
rm -r ./published

cp -r ./src ./published

for f in $(find ./published/ -type f); do
	sha1sum $f > "${f}.sha1";
done
