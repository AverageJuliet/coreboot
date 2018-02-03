#!/bin/bash
#

set -e

snb_ivb=('butterfly' 'link' 'lumpy' 'parrot' 'stout' 'stumpy')
hsw=('falco' 'leon' 'mccloud' 'monroe' 'panther' 'peppy' 'tricky' 'wolf' \
	'zako');
bdw=('auron_paine' 'auron_yuna' 'buddy' 'gandof' 'guado' \
     'lulu' 'rikku' 'samus' 'tidus');
byt=('banjo' 'candy' 'clapper' 'enguarde' 'glimmer' 'gnawty' 'heli' \
	'kip' 'ninja' 'orco' 'quawks' 'squawks' 'sumo' 'swanky' 'winky');
bsw=('banon' 'celes' 'cyan' 'edgar' 'kefka' 'reks' 'relm' \
	'setzer' 'terra' 'ultima' 'wizpig');
skl=('asuka' 'caroline' 'cave' 'chell' 'lars'  'sentry')
kbl=('atlas' 'eve' 'fizz' 'nami' 'nautilus' 'nocturne' 'rammus' 'soraka')
str=('aleena' 'barla' 'careena' 'kasumi' 'liara' 'treeya')
cml=('akemi' 'dragonair' 'dratini' 'duffy' 'faffy' 'helios' 'jinlon' 'kaisa' \
     'kindred' 'kled' 'kohaku' 'nightfury' 'noibat' 'wyvern')
zen2=('morphius')
purism=('librem_13v1' 'librem_15v2' 'librem_13v2' 'librem_15v3' 'librem_13v4' \
        'librem_15v4' 'librem_mini' 'librem_mini_v2' 'librem_14')

json_file=cbmodels.json
rom_path=https://www.mrchromebox.tech/files/firmware/full_rom/
echo -e "{" > $json_file

if [ -z "$1" ]; then
	build_targets=($(printf "%s " "${snb_ivb[@]}" "${hsw[@]}" "${bdw[@]}" \
		"${byt[@]}" "${bsw[@]}" "${skl[@]}" "${kbl[@]}" "${str[@]}" \
		"${cml[@]}" "${zen2[@]}" "${purism[@]}"));
else
	build_targets=($@)
fi

for device in ${build_targets[@]}
do
	filename="coreboot_tiano-${device}-mrchromebox_$(date +"%Y%m%d").rom"
	rm -f ~/dev/firmware/${filename}*
	rm -rf ./build
	cp configs/.config.${device}.uefi .config
	make clean
	make olddefconfig
	make -j$(nproc)
	cp ./build/coreboot.rom ./${filename}
	if [ "${device}" == "nightfury" ]; then
		cbfstool ${filename} add -t raw -n vbt-nightfury-qled.bin -f blobs/mainboard/google/nightfury/vbt-nightfury-qled.bin
	elif [ "${device}" == "drawman" ]; then
		cbfstool ${filename} add -t raw -n vbt_drawman.bin -f blobs/mainboard/google/drawcia/vbt_drawman.bin
	fi
	cbfstool ${filename} print
	sha1sum ${filename} > ${filename}.sha1
	echo -e "\t\"${device}\": {" >> $json_file
	echo -e "\t\t\"url\": \"${rom_path}${filename}\"," >> $json_file
	echo -e "\t\t\"sha1\": \"$(cat ${filename}.sha1 | awk 'NR==1{print $1}')\"" >> $json_file
	echo -e "\t}," >> $json_file
	mv ${filename}* ~/dev/firmware/
	if [ "${device}" == "peppy" ]; then
		filename="coreboot_tiano-${device}_elan-mrchromebox_$(date +"%Y%m%d").rom"
		rm -rf ./build
		sed -i 's/# CONFIG_ELAN_TRACKPAD_ACPI is not set/CONFIG_ELAN_TRACKPAD_ACPI=y/' .config
		make
		cp ./build/coreboot.rom ./${filename}
		cbfstool ${filename} print
		sha1sum ${filename} > ${filename}.sha1
		echo -e "\t\"${device}-elan\": {" >> $json_file
		echo -e "\t\t\"url\": \"${rom_path}${filename}\"," >> $json_file
		echo -e "\t\t\"sha1\": \"$(cat ${filename}.sha1 | awk 'NR==1{print $1}')\"" >> $json_file
		echo -e "\t}," >> $json_file
		mv ${filename}* ~/dev/firmware/
	fi
done
echo -e "}" >> $json_file
