rm -rf zsup*.xcarchive/dSYMs
if [ -f zsup*.xcarchive/Info.plist ]; then
	rm zsup*.xcarchive/Info.plist
fi

if [ -d zsup*.xcarchive/Products ]; then
	mv zsup*.xcarchive/Products/* zsup*.xcarchive/
	rm -rf zsup*.xcarchive/Products
fi
pkgbuild --root ./zsup*.xcarchive --component-plist zsup.plist --identifier "com.f1recat.pkg.zsup" --version 1.0 --install-location "/" zsup.pkg

