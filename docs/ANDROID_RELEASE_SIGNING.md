# Android release signing

The project loads release signing credentials from `android/key.properties`.
The real properties file and all `.jks`/`.keystore` files are excluded from Git.

## 1. Create the upload key

Run this command from the project root and enter a strong password when asked:

```powershell
& 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -genkeypair -v -keystore android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the keystore and its passwords in a separate, secure backup. Losing them can make future app updates difficult.

## 2. Create the local properties file

Copy `android/key.properties.example` to `android/key.properties`, then replace the password placeholders with the values used for the key:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

## 3. Create the Play Store bundle

After the signing files are ready, create the bundle with:

```text
flutter build appbundle --release
```

The resulting file is `build/app/outputs/bundle/release/app-release.aab`.
Before uploading it, back up `android/app/upload-keystore.jks`, the passwords, and the alias in a secure location outside the repository.
