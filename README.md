# buildRLib (2021-03-04)

For details on how to manage multiple Git accounts on a single computer, see:
```
https://www.freecodecamp.org/news/manage-multiple-github-accounts-the-ssh-way-2dadc30ccaca/
```

If the following error regarding the R package is encountered on a macOS computer:
```
Error : .onLoad failed in loadNamespace() for 'Cairo', details:
  call: dyn.load(file, DLLpath = DLLpath, ...)
  error: unable to load shared object '/Library/Frameworks/R.framework/Versions/3.3/Resources/library/Cairo/libs/Cairo.so':
  dlopen(/Library/Frameworks/R.framework/Versions/3.3/Resources/library/Cairo/libs/Cairo.so, 6): Library not loaded: /opt/X11/lib/libXrender.1.dylib
  Referenced from: /Library/Frameworks/R.framework/Versions/3.3/Resources/library/Cairo/libs/Cairo.so
  Reason: image not found
Error: package or namespace load failed for ‘Cairo’
```
consider installing X11 for Mac, which is called XQuartz.
It no longer ships with OS X.
To install X11/XQuartz, visit: **https://www.xquartz.org/**
For more information, see the following blog post:

https://izziswift.com/include-cairo-r-on-a-mac/

