
#!/bin/sh

rm -rf resigned.ipa
rm -rf Payload
rm -rf mobile.plist
rm -rf entitlements.plist

/usr/bin/security cms -D -i embedded.mobileprovision >  mobile.plist
/usr/libexec/PlistBuddy -c "Print :Entitlements" mobile.plist -x > entitlements.plist

TEAM_NAME=`/usr/libexec/PlistBuddy -c "Print :TeamName" mobile.plist`
TEAM_ID=`/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.developer.team-identifier" mobile.plist`
FILE_NAME=$"iPhone Distribution: ${TEAM_NAME}"
APP_ID=`/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" mobile.plist`
APP_ID=`Echo ${APP_ID} | sed "s/${TEAM_ID}.//g"`

IPA_FOLDER=""
for ipa_item in ./*.ipa
do
    IPA_FOLDER=$ipa_item
done

/usr/bin/unzip -q ${IPA_FOLDER}

APP_FOLDER=""
for app_item in ./Payload/*.app
do
    if test -d $app_item
    then
        APP_FOLDER=$app_item
    fi
done

cp -rf embedded.mobileprovision ${APP_FOLDER}/embedded.mobileprovision 
/usr/libexec/PlistBuddy -c "Set:CFBundleIdentifier ${APP_ID}" ${APP_FOLDER}/Info.plist 

for framework_item in ${APP_FOLDER}/Frameworks/*.framework
do
    if test -d $framework_item
    then
        rm -rf ${framework_item}/_CodeSignature
        /usr/bin/codesign -vvv -fs "$FILE_NAME" --no-strict --entitlements=entitlements.plist ${framework_item}
    fi
done

rm -rf ${APP_FOLDER}/_CodeSignature
/usr/bin/codesign -vvv -fs "$FILE_NAME" --no-strict --entitlements=entitlements.plist ${APP_FOLDER}

/usr/bin/zip -qry resigned.ipa Payload

rm -rf Payload
rm -rf mobile.plist
rm -rf entitlements.plist





