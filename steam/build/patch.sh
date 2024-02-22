#!/bin/bash

echo
echo "RUNNING ADDITIONAL BATOCERA CONTY PATCHES"
echo
echo "fixing libc dthash"
ver=$(ldd --version | head -n1 | rev | awk '{print $1}' | rev)
echo -e "\n\nPREPARING LIBC $ver DT_HASH FIX FOR STEAM...\n\n"

# prepare libc patcher
f=/tmp/fixlibc
rm $f 2>/dev/null
echo '#!/bin/bash' >> $f
echo "ver=$ver" >> $f
echo 'mkdir ~/build 2>/dev/null && rm -rf ~/build/glibc && cd ~/build' >> $f
echo 'git clone https://sourceware.org/git/glibc.git ~/build/glibc' >> $f
echo 'cd ~/build/glibc' >> $f
echo "git checkout glibc-$ver" >> $f
echo 'mkdir ~/build/glibc/build && cd ~/build/glibc/build' >> $f
echo 'echo -e "\n\nCONFIGURING...\n\n"' >> $f
echo 'export CFLAGS="$CFLAGS -O3 -fno-stack-protector -fno-PIC -D_FORTIFY_SOURCE=0"' >> $f
echo 'export LDFLAGS="$LDFLAGS -Wl,--hash-style=both -Wl,-z,norelro"' >> $f
echo 'export LDFLAGS.so="-Wl,--hash-style=both -Wl,-z,norelro"' >> $f
echo 'export LDFLAGS-rtld="-Wl,--hash-style=both -Wl,-z,norelro"' >> $f
echo '../configure \' >> $f
echo '    --prefix=/usr \' >> $f
echo '    --with-headers=/usr/include \' >> $f
echo '    --with-bugurl=https://bugs.archlinux.org/ \' >> $f
echo '    --enable-bind-now \' >> $f
echo '    --enable-cet \' >> $f
echo '    --enable-kernel=4.4 \' >> $f
echo '    --enable-multi-arch \' >> $f
echo '    --disable-stack-protector \' >> $f
echo '    --enable-systemtap \' >> $f
echo '    --disable-crypt \' >> $f
echo '    --disable-profile \' >> $f
echo '    --disable-werror \' >> $f
echo '    --libdir=/usr/lib \' >> $f
echo '    --libexecdir=/usr/lib' >> $f
echo 'echo -e "\n\nCOMPILING...\n\n"' >> $f
echo "make -j$(nproc) 1>/dev/null 2>/dev/null" >> $f
echo 'echo -e "\n\nINSTALLING...\n\n"' >> $f
echo 'sudo make install 1>/dev/null 2>/dev/null' >> $f
echo 'cd ~/' >> $f
echo 'rm -rf ~/build/glibc' >> $f

# run libc patcher
dos2unix $f 2>/dev/null
chmod 777 $f 2>/dev/null
/tmp/fixlibc

# prepare/preload
echo "fixing nvidia ld.so.cache"
rm /usr/bin/prepare 2>/dev/null
rm /usr/bin/preload 2>/dev/null
wget -q --tries=10 -O /usr/bin/prepare "https://raw.githubusercontent.com/uureel/batocera.pro/main/steam/build/prepare.sh"
dos2unix /usr/bin/prepare 2>/dev/null 
chmod 777 /usr/bin/prepare 2>/dev/null
cp /usr/bin/prepare /usr/bin/preload 2>/dev/null

# fix for nvidia lutris
echo "fixing lutris"
cd /opt
	git clone https://github.com/lutris/lutris
	sed -i 's,os.geteuid() == 0,os.geteuid() == 888,g' /opt/lutris/lutris/gui/application.py 2>/dev/null
	cp /usr/bin/lutris /usr/bin/lutris-git 2>/dev/null
	rm /usr/bin/lutris 2>/dev/null
	  wget -q --tries=10 --no-check-certificate --no-cache --no-cookies -O /usr/bin/lutris https://raw.githubusercontent.com/uureel/batocera.pro/main/steam/build/lutris.sh
	  dos2unix /usr/bin/lutris 2>/dev/null
	  chmod 777 /usr/bin/lutris

# add ~/.bashrc&profile env
echo "fixing .bashrc and .profile"
rm ~/.bashrc
	echo '#!/bin/bash' >> ~/.bashrc
	echo 'ulimit -H -n 819200 && ulimit -S -n 819200 && sysctl -w fs.inotify.max_user_watches=8192000 vm.max_map_count=2147483642 fs.file-max=8192000 >/dev/null 2>&1' >> ~/.bashrc
	echo 'export XDG_CURRENT_DESKTOP=XFCE' >> ~/.bashrc
	echo 'export DESKTOP_SESSION=XFCE' >> ~/.bashrc
	echo 'export DISPLAY=:0.0' >> ~/.bashrc
	echo 'export GDK_SCALE=1' >> ~/.bashrc
	echo 'export USER=root' >> ~/.bashrc
dos2unix ~/.bashrc
chmod 777 ~/.bashrc
cp ~/.bashrc ~/.profile

# fix for winestaging bork
echo "fixing paths for wine staging"
rm -rf /lib32 2>/dev/null
rm -rf /share 2>/dev/null
ln -sf /usr/lib32 /lib32
ln -sf /usr/share /share

# fix borked faudio 
echo "fixing faudio staging"
yes "Y" | pacman -S gstreamer
yes "Y" | pacman -S faudio
cd /tmp/
f=/tmp/lib32faudio.pkg.tar.zst
link=https://builds.garudalinux.org/repos/chaotic-aur/x86_64/lib32-faudio-tkg-git-24.02.r0.g38e9da7-1-x86_64.pkg.tar.zst
wget -O "$f" "$link"
yes "Y" | pacman -U "$f"
rm "$f"
cd ~/

# run additional fixes
echo "fixing root apps"
sed -i 's,/opt/google/chrome/google-chrome,/opt/google/chrome/google-chrome --no-sandbox --test-type,g' /usr/bin/google-chrome-stable 2>/dev/null
sed -i 's,/opt/spotify/spotify,/opt/spotify/spotify --no-sandbox --test-type,g' /usr/bin/spotify 2>/dev/null
sed -i '/<description>.*<\/description>/d' /etc/fonts/fonts.conf 2>/dev/null
sed -i '/<description>.*<\/description>/d' /etc/fonts/conf.d/* 2>/dev/null
cd /usr/lib
#rm $(find /usr/lib | grep nvidia) 2>/dev/null
find . -path ./python\* -prune -o -type f -name \*nvidia\* -exec rm {} +
cd /usr/lib32 
rm $(find /usr/lib32 | grep nvidia) 2>/dev/null

echo "fixing samba lockups"
rm /usr/bin/samba* 2>/dev/null
rm /usr/bin/smb* 2>/dev/null
rm -rf ~/build 2>/dev/null

# confirm libc patch status
echo "checking libc patch"
h=/tmp/hash && rm $h 2>/dev/null
readelf -d /usr/lib/libc.so.6 | grep 'HASH' >> $h
	if [[ "$(cat $h | grep '(HASH)')" != "" ]] && [[ "$(cat $h | grep '(GNU_HASH)')" != "" ]]; then
		echo
		echo "LIBC DT_HASH PATCHED OK!"
		echo
	else
		echo
		echo "LIBC DT_HASH PATCH FAILED..."
		echo	
	fi
rm $f 2>/dev/null
rm $h 2>/dev/null

echo
echo "patch.sh done."
echo "______________"
echo
echo 

exit 0
#exit