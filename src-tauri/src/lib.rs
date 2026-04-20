#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
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
            commands::share_file_android
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[cfg(target_os = "android")]
mod commands {
    use tauri::command;
    
    #[command]
    pub fn share_file_android(_app: tauri::AppHandle, file_path: String, mime_type: String, title: String) -> Result<bool, String> {
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
