echo "\033[32m[1/4] De-register Existing Service\033[0m"
launchctl unload /usr/local/Cellar/guillotine/com.bytedance.GuillotineService.plist

echo "\033[32m[2/4] Build Guillotine Package\033[0m"
swift build --configuration release

echo "\033[32m[3/4] Setup Binaries\033[0m"
rm -rf /usr/local/Cellar/guillotine
rm -rf /usr/local/bin/gltc

mkdir /usr/local/Cellar/guillotine

cp -r .build/release/gltc /usr/local/Cellar/guillotine
cp -r .build/release/GuillotineService /usr/local/Cellar/guillotine
cp -r .build/release/GuillotineKit_GuillotineClient.bundle /usr/local/Cellar/guillotine

cp -r Sources/GuillotineService/com.bytedance.GuillotineService.plist /usr/local/Cellar/guillotine

chmod u+x /usr/local/Cellar/guillotine/gltc
chmod u+x /usr/local/Cellar/guillotine/GuillotineService

cd /usr/local/bin
ln -s ../Cellar/guillotine/gltc gltc
chmod u+x gltc

echo "\033[32m[4/4]Register Guillotine Service\033[0m"
launchctl load /usr/local/Cellar/guillotine/com.bytedance.GuillotineService.plist

echo "\033[32mInstallation Completed\033[0m"
