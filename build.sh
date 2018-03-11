#!/bin/sh

# Minimum sdk version
minSdkVersion=19

. ./semver_bash/semver.sh

allTheStuff=$(sdkmanager --list --include_obsolete --verbose 2>/dev/null | tr '\r' '\n' | uniq)
allTheStuff="$allTheStuff
"
available=""
line=""
inList=0
skipLines=0

while IFS='' read -r nextline; do
	if [ $skipLines -eq 1 ]; then
		skipLines=0
		line="$nextline"
		continue
	fi
	if [ -n "$nextline" ] && [ -z "${nextline##-*}" ]; then
		inList=0
		skipLines=1
		if [ -n "$line" ] && [ "${line#Available}" != "$line" ]; then
			inList=1
		fi
		line="$nextline"
		continue
	fi

	if [ $inList -eq 1 ] && [ -n "$line" ] && [ "${line# }" = "$line" ] && [ "$line" != "done" ]; then
		available="${available}
${line}"
	fi

	line="$nextline"
done <<EOF
$allTheStuff
EOF

versionRE="[0-9.]+(-[0-9A-Za-z.-]+){0,1}$"
sdkPrefix="platforms;android-"
buildToolPrefix="build-tools;"
googleApiPrefix="add-ons;addon-google_apis-google-"


sdkVersions=$(echo "$available" | grep -E -o "${sdkPrefix}${versionRE}" | grep -E -o "$versionRE" | sort -n -r)
buildTools=$(echo "$available" | grep -E -o "${buildToolPrefix}${versionRE}" | grep -E -o "$versionRE")
googleApis=$(echo "$available" | grep -E -o "${googleApiPrefix}${versionRE}" | grep -E -o "$versionRE")

echo "Available SDK versions:"
echo "$sdkVersions"
echo ""
echo "Available build tools:"
echo "$buildTools"
echo ""
echo "Available google APIs:"
echo "$googleApis"
echo ""

if [ "$TAG" = "$DEFAULT_TAG" ]; then
	TAG_PREFIX=""
else
	TAG_PREFIX="$TAG"
fi
TAG_PREFIX="${TAG_PREFIX}${TAG_PREFIX:+-}"

multiVersions=""
while read -r version; do
	if [ -z "$version" ]; then
		continue
	fi
	if semverLT "$version" "$minSdkVersion"; then
		continue
	fi
	multiVersions="
$version
$multiVersions
"
done <<EOF
$sdkVersions
EOF

minVersion=""
while read -r version; do
	if [ -z "$version" ]; then
		continue
	fi
	if [ -z "$minVersion" ]; then
		minVersion="$version"
		continue
	fi
	if semverLT "$version" "$minVersion"; then
		minVersion="$version"
	fi
done <<EOF
$multiVersions
EOF

# TODO: check that these packages actually exist
toinstall="platform-tools \"extras;android;m2repository\" \"extras;google;m2repository\" \"extras;google;market_apk_expansion\" \"extras;google;market_licensing\" \"extras;google;webdriver\""
while read -r version; do
	if [ -z "$version" ]; then
		continue
	fi
	echo "android sdk $version"

	addtoinstall="\"${sdkPrefix}${version}\""
	while read -r googleApiVersion; do
		if [ "$version" = "$googleApiVersion" ]; then
			echo "    google api $googleApiVersion"
			addtoinstall="$addtoinstall \"${googleApiPrefix}${googleApiVersion}\""
		fi
	done <<EOF
$googleApis
EOF

	if [ -z "$toinstall" ]; then
		toinstall="$addtoinstall"
	else
		toinstall="$toinstall $addtoinstall"
	fi
done <<EOF
$multiVersions
EOF

while read -r buildtoolVersion; do
	if semverLE "$minVersion" "$buildtoolVersion"; then
		echo "    build tools $buildtoolVersion"
        toinstall="$toinstall \"${buildToolPrefix}${buildtoolVersion}\""
	fi
done <<EOF
$buildTools
EOF

# shellcheck disable=SC2028
echo "$toinstall" > "toinstall"
