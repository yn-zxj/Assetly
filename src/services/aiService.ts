import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';
import type { AISettings, AIRecognitionResult } from '../types/settings';
import { logInfo, logError } from '../utils/logger';

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

function createModel(settings: AISettings) {
  return new ChatOpenAI({
    modelName: settings.ai_text_model,
    openAIApiKey: settings.ai_api_key,
    configuration: {
      baseURL: settings.ai_api_url,
    },
    temperature: 0.2,
    maxTokens: 1024,
  });
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

  const model = createModel(settings);
  const response = await model.invoke([
    new SystemMessage(SYSTEM_PROMPT),
    new HumanMessage(text),
  ]);

  const content = String(response.content);
  logInfo('文字识别完成', 'AIService');
  return parseResult(content);
}

export async function recognizeByImage(
  imageBase64: string,
  settings: AISettings
): Promise<AIRecognitionResult> {
  if (!settings.ai_api_key) {
    throw new Error('请先配置 API Key');
  }

  logInfo('开始图片识别', 'AIService');

  const model = new ChatOpenAI({
    modelName: settings.ai_vision_model,
    openAIApiKey: settings.ai_api_key,
    configuration: {
      baseURL: settings.ai_api_url,
    },
    temperature: 0.2,
    maxTokens: 1024,
  });

  const response = await model.invoke([
    new SystemMessage(SYSTEM_PROMPT),
    new HumanMessage({
      content: [
        {
          type: 'text',
          text: '请识别这张图片中的物品，返回 JSON 格式数据。',
        },
        {
          type: 'image_url',
          image_url: {
            url: imageBase64,
          },
        },
      ],
    }),
  ]);

  const content = String(response.content);
  logInfo('图片识别完成', 'AIService');
  return parseResult(content);
}

export function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}
