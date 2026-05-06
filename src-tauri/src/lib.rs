#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|_app| {
            // 开发阶段自动弹出 WebView DevTools，方便在 Network 面板查看请求
            // 参考：https://v2.tauri.app/zh-cn/develop/debug/application/
            #[cfg(debug_assertions)]
            {
                use tauri::Manager;
                if let Some(window) = _app.get_webview_window("main") {
                    window.open_devtools();
                }
            }
            Ok(())
        })
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_http::init())
        .plugin(tauri_plugin_sql::Builder::new().build())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(
            tauri_plugin_log::Builder::new()
                .target(tauri_plugin_log::Target::new(
                    tauri_plugin_log::TargetKind::LogDir {
                        file_name: Some("assetly".to_string()),
                    },
                ))
                .target(tauri_plugin_log::Target::new(
                    tauri_plugin_log::TargetKind::Stdout,
                ))
                .level(log::LevelFilter::Info)
                .build(),
        )
        .invoke_handler(tauri::generate_handler![
            commands::share_file_android,
            ai::ai_chat_stream
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[cfg(target_os = "android")]
mod commands {
    use tauri::command;
    
    #[command]
    pub fn share_file_android(_app: tauri::AppHandle, _file_path: String, _mime_type: String, _title: String) -> Result<bool, String> {
        // This will be called from the Android side via MainActivity
        // For now, we'll handle it in the frontend using Web Share API
        Ok(false)
    }
}

#[cfg(not(target_os = "android"))]
mod commands {
    use tauri::command;
    
    #[command]
    pub fn share_file_android(_app: tauri::AppHandle, _file_path: String, _mime_type: String, _title: String) -> Result<bool, String> {
        Ok(false)
    }
}

mod ai {
    use futures_util::StreamExt;
    use tauri::ipc::Channel;

    /// 流式调用 OpenAI 兼容的 chat completions 接口。
    ///
    /// 背景：@tauri-apps/plugin-http 的 fetch 会一次性读完整个 response body，
    /// 导致 SSE 的流式无法在前端真正生效。这里用 reqwest 的 bytes_stream
    /// 直接从服务端读取每个 TCP chunk，通过 Tauri Channel 实时推给前端。
    ///
    /// 前端收到的每个事件是一段原始 SSE 文本（可能跨 chunk），
    /// 由前端自己按 `data: ...\n\n` 拆解。
    #[tauri::command]
    pub async fn ai_chat_stream(
        url: String,
        api_key: String,
        body: serde_json::Value,
        on_event: Channel<StreamEvent>,
    ) -> Result<(), String> {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(300))
            .build()
            .map_err(|e| format!("build client failed: {}", e))?;

        let resp = client
            .post(&url)
            .bearer_auth(&api_key)
            .header("Content-Type", "application/json")
            .header("Accept", "text/event-stream")
            .json(&body)
            .send()
            .await
            .map_err(|e| format!("request failed: {}", e))?;

        let status = resp.status();
        if !status.is_success() {
            let text = resp.text().await.unwrap_or_default();
            return Err(format!("HTTP {}: {}", status, text));
        }

        // 正常流：按 chunk 推送给前端
        let _ = on_event.send(StreamEvent::Start { status: status.as_u16() });
        let mut stream = resp.bytes_stream();
        while let Some(chunk) = stream.next().await {
            match chunk {
                Ok(bytes) => {
                    let text = String::from_utf8_lossy(&bytes).to_string();
                    if !text.is_empty() {
                        let _ = on_event.send(StreamEvent::Chunk { data: text });
                    }
                }
                Err(e) => {
                    let _ = on_event.send(StreamEvent::Error { message: e.to_string() });
                    return Err(format!("stream error: {}", e));
                }
            }
        }
        let _ = on_event.send(StreamEvent::Done);
        Ok(())
    }

    #[derive(Clone, serde::Serialize)]
    #[serde(rename_all = "camelCase", tag = "type")]
    pub enum StreamEvent {
        Start { status: u16 },
        Chunk { data: String },
        Error { message: String },
        Done,
    }
}
