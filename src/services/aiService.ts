import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';
import type { AISettings, AIRecognitionResult } from '../types/settings';
import { logInfo, logError } from '../utils/logger';
import { getHttpFetch } from './httpFetch';

const SYSTEM_PROMPT = `你是一个家庭物品管理助手。用户会提供物品的文字描述或图片，你需要识别物品信息并判断它是普通物品还是药品。

请严格按以下 JSON 格式返回，不要包含任何其他内容：

{
  "item_type": "item" | "medicine",
  "name": "物品名称",
  "description": "物品描述",
  "category_id": "",
  "location_id": "",
  "purchase_date": "YYYY-MM-DD 或空字符串",
  "purchase_price": 0,
  "quantity": 1,
  "warranty_expiry": "YYYY-MM-DD 或空字符串（普通物品）",
  "shelf_life_expiry": "YYYY-MM-DD 或空字符串（普通物品）",
  "medicine_type": "internal | external | emergency | injection | inhalation | ophthalmic | topical 或空字符串（药品）",
  "expiry_date": "YYYY-MM-DD 或空字符串（药品）",
  "dosage_instructions": "服用说明（药品）",
  "remaining_quantity": 0,
  "unit": "片/粒/支/瓶/盒/袋/包/条/贴/枚/滴/喷/g/mg/ml 或空字符串",
  "manufacturer": "生产厂商（药品）",
  "confidence": 0.95
}

规则：
1. item_type 为 "medicine" 时，表示这是药品/药物/保健品，需要填写药品相关字段
2. item_type 为 "item" 时，表示普通物品，填写普通物品字段
3. 无法识别的字段请留空字符串或给合理的默认值
4. confidence 表示你对识别结果的置信度（0-1之间）
5. 日期格式必须是 YYYY-MM-DD
6. 只返回纯 JSON，不要 markdown 代码块，不要额外解释`;

function createModel(settings: AISettings, isVision = false) {
  const isSeparate = settings.ai_model_mode === 'separate';
  const modelName = isVision && isSeparate
    ? settings.ai_vision_model
    : settings.ai_text_model;
  const apiKey = isVision && isSeparate
    ? settings.ai_vision_api_key
    : settings.ai_api_key;
  const baseURL = isVision && isSeparate
    ? settings.ai_vision_api_url
    : settings.ai_api_url;
  return new ChatOpenAI({
    model: modelName,
    apiKey: apiKey,
    configuration: { baseURL, fetch: getHttpFetch() },
    temperature: 1,
    maxTokens: 4096,
    timeout: 300000,
    maxRetries: 0,
    streaming: true,
  });
}

function describeError(err: unknown): string {
  const e = err as any;
  const parts: string[] = [];
  if (e?.name) parts.push(`name=${e.name}`);
  if (e?.status) parts.push(`status=${e.status}`);
  if (e?.code) parts.push(`code=${e.code}`);
  if (e?.message) parts.push(`message=${e.message}`);
  // OpenAI SDK 的 APIConnectionError 会把底层 fetch 错误放在 cause 里
  const cause = e?.cause;
  if (cause) {
    if (typeof cause === 'string') parts.push(`cause=${cause}`);
    else if (cause?.message) parts.push(`cause=${cause.name || 'Error'}:${cause.message}`);
  }
  // 尝试读取 body（HTTP 非 2xx 响应详情）
  if (e?.error) {
    try {
      parts.push(`error=${JSON.stringify(e.error).slice(0, 200)}`);
    } catch {
      /* ignore */
    }
  }
  return parts.join(' | ') || String(err);
}

async function streamInvoke(
  model: ChatOpenAI,
  messages: any[],
  onFirstChunk?: () => void,
): Promise<string> {
  const stream = await model.stream(messages);
  let content = '';
  let first = true;
  for await (const chunk of stream as AsyncIterable<any>) {
    if (first) {
      first = false;
      onFirstChunk?.();
    }
    const part = chunk?.content;
    if (typeof part === 'string') {
      content += part;
    } else if (Array.isArray(part)) {
      for (const p of part) {
        if (typeof p === 'string') content += p;
        else if (p?.text) content += p.text;
      }
    }
  }
  return content;
}

function parseResult(content: string): AIRecognitionResult {
  try {
    const cleaned = content.trim().replace(/^```json\s*/, '').replace(/```$/, '');
    const parsed = JSON.parse(cleaned);
    return {
      item_type: parsed.item_type === 'medicine' ? 'medicine' : 'item',
      name: String(parsed.name || ''),
      description: String(parsed.description || ''),
      category_id: String(parsed.category_id || ''),
      location_id: String(parsed.location_id || ''),
      purchase_date: String(parsed.purchase_date || ''),
      purchase_price: Number(parsed.purchase_price || 0),
      quantity: Number(parsed.quantity || 1),
      warranty_expiry: parsed.warranty_expiry ? String(parsed.warranty_expiry) : undefined,
      shelf_life_expiry: parsed.shelf_life_expiry ? String(parsed.shelf_life_expiry) : undefined,
      medicine_type: parsed.medicine_type ? String(parsed.medicine_type) : undefined,
      expiry_date: parsed.expiry_date ? String(parsed.expiry_date) : undefined,
      dosage_instructions: parsed.dosage_instructions ? String(parsed.dosage_instructions) : undefined,
      remaining_quantity: parsed.remaining_quantity !== undefined ? Number(parsed.remaining_quantity) : undefined,
      unit: parsed.unit ? String(parsed.unit) : undefined,
      manufacturer: parsed.manufacturer ? String(parsed.manufacturer) : undefined,
      confidence: Number(parsed.confidence || 0.5),
    };
  } catch (err) {
    logError(`AI 返回解析失败: ${content.slice(0, 200)}`, 'AIService');
    throw new Error('AI 返回格式异常，请重试');
  }
}

export async function recognizeByText(
  text: string,
  settings: AISettings
): Promise<AIRecognitionResult> {
  if (!settings.ai_api_key) {
    throw new Error('请先配置 API Key');
  }

  logInfo('开始文字识别', 'AIService');
  const t0 = Date.now();

  const model = createModel(settings, false);
  let content = '';
  try {
    content = await streamInvoke(
      model,
      [new SystemMessage(SYSTEM_PROMPT), new HumanMessage(text)],
      () => logInfo(`文字识别首包到达(${Date.now() - t0}ms)`, 'AIService'),
    );
  } catch (err) {
    const detail = describeError(err);
    logError(`文字识别请求失败(耗时${Date.now() - t0}ms): ${detail}`, 'AIService');
    throw new Error(`文字识别失败: ${detail}`);
  }

  const tReq = Date.now() - t0;
  if (!content.trim()) {
    logError(`文字识别返回为空(耗时${tReq}ms)`, 'AIService');
    throw new Error('AI 返回内容为空，可能是 maxTokens 不足或模型类型不匹配');
  }
  logInfo(`文字识别原始返回(耗时${tReq}ms,${content.length}字符): ${content}`, 'AIService');
  const parsed = parseResult(content);
  logInfo(`文字识别解析结果: ${JSON.stringify(parsed)}`, 'AIService');
  return parsed;
}

export async function recognizeByImage(
  imageBase64: string,
  settings: AISettings
): Promise<AIRecognitionResult> {
  if (!settings.ai_api_key) {
    throw new Error('请先配置 API Key');
  }

  logInfo('开始图片识别', 'AIService');
  const t0 = Date.now();

  const model = createModel(settings, true);

  let content = '';
  try {
    content = await streamInvoke(
      model,
      [
        new SystemMessage(SYSTEM_PROMPT),
        new HumanMessage({
          content: [
            {
              type: 'text',
              text: '请识别这张图片中的物品，返回 JSON 格式数据。',
            },
            {
              type: 'image_url',
              image_url: { url: imageBase64 },
            },
          ],
        }),
      ],
      () => logInfo(`图片识别首包到达(${Date.now() - t0}ms)`, 'AIService'),
    );
  } catch (err) {
    const detail = describeError(err);
    logError(`图片识别请求失败(耗时${Date.now() - t0}ms): ${detail}`, 'AIService');
    throw new Error(`图片识别失败: ${detail}`);
  }

  const tReq = Date.now() - t0;
  if (!content.trim()) {
    logError(`图片识别返回为空(耗时${tReq}ms)`, 'AIService');
    throw new Error('AI 返回内容为空，可能是 maxTokens 不足或模型不支持图片');
  }
  logInfo(`图片识别原始返回(耗时${tReq}ms,${content.length}字符): ${content}`, 'AIService');
  const parsed = parseResult(content);
  logInfo(`图片识别解析结果: ${JSON.stringify(parsed)}`, 'AIService');
  return parsed;
}

export function fileToBase64(file: File): Promise<string> {
  // 压缩到最长边 1024px，JPEG 0.8，避免 base64 body 过大导致请求被取消
  return compressAndEncode(file, 1024, 0.8);
}

function compressAndEncode(
  file: File,
  maxSize: number,
  quality: number,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = reject;
    reader.onload = () => {
      const img = new Image();
      img.onerror = reject;
      img.onload = () => {
        try {
          const longest = Math.max(img.width, img.height);
          const scale = longest > maxSize ? maxSize / longest : 1;
          const w = Math.max(1, Math.round(img.width * scale));
          const h = Math.max(1, Math.round(img.height * scale));
          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext('2d');
          if (!ctx) {
            resolve(String(reader.result));
            return;
          }
          ctx.drawImage(img, 0, 0, w, h);
          const out = canvas.toDataURL('image/jpeg', quality);
          logInfo(
            `图片压缩: ${img.width}x${img.height} -> ${w}x${h}, base64 ${out.length} 字节`,
            'AIService',
          );
          resolve(out);
        } catch (err) {
          reject(err);
        }
      };
      img.src = String(reader.result);
    };
    reader.readAsDataURL(file);
  });
}
