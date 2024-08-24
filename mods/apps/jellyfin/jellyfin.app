#!/bin/bash

deploy_container() {

    docker run -d \
      --name="${app_name}" \
      -e PUID=1000 \
      -e PGID=1000 \
      -e TZ="${time_zone}" \
      -e JELLYFIN_PublishedServerUrl="${jf_serverurl}" \
      -p "${expose}""${port_number}":8096 \
      -v "${appdata_path}":/config \
      -v "${tv_path}":/data/tvshows \
      -v "${movies_path}":/data/movies \
      --device=/dev/dri:/dev/dri \
      --restart unless-stopped \
      lscr.io/linuxserver/jellyfin:"${version_tag}"

    # display app deployment information
    appverify "$app_name"
}
