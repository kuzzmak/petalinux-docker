docker run ^
    --mount type=bind,source="C:\Users\tonkec\Downloads\bsp_source",target="/home/petalinux/project" ^
    -it --rm build-plnx:2023.2