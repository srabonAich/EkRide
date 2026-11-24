package com.ekride.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import java.io.File;
import java.nio.file.Files;

@Configuration
@ConfigurationProperties(prefix = "ekride.google")
public class GoogleMapsProperties {
    private String apiKey;
    private String apiKeyFile;
    private boolean demoModeFallback = true;

    public String getResolvedApiKey() {
        if (apiKey != null && !apiKey.trim().isEmpty()) {
            return apiKey.trim();
        }
        if (apiKeyFile != null && !apiKeyFile.trim().isEmpty()) {
            try {
                File f = new File(apiKeyFile.trim());
                if (!f.exists()) {
                    // Try looking in parent directory (useful when running from backend subfolder)
                    f = new File(".." + File.separator + apiKeyFile.trim());
                }
                if (f.exists()) {
                    return Files.readString(f.toPath()).trim();
                }
            } catch (Exception ignored) {}
        }
        return "";
    }

    public String getApiKey() { return apiKey; }
    public void setApiKey(String apiKey) { this.apiKey = apiKey; }
    public String getApiKeyFile() { return apiKeyFile; }
    public void setApiKeyFile(String apiKeyFile) { this.apiKeyFile = apiKeyFile; }
    public boolean isDemoModeFallback() { return demoModeFallback; }
    public void setDemoModeFallback(boolean demoModeFallback) { this.demoModeFallback = demoModeFallback; }
}
