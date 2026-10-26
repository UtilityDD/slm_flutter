# Emergency — জরুরি

`EmergencyDirectoryScreen` loads `assets/data/districtEmergencyServices.json`.

Each row: name, type, district, location, phone, optional address. Tap dials via `url_launcher`.

Needs `RECORD_AUDIO` only for other features; this screen needs `INTERNET` only if anything remote is added later. Phone intents work offline if the JSON is bundled (it is).
