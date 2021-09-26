#!/usr/bin/env bash

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <server_type> <minecraft_version> <server_version> <package_release_num> [with_suffic]"
    exit 1
fi


set -ex

BASEDIR=$(realpath "$(dirname "$0")")
TMPLDIR="${BASEDIR}/template"

export srv_type="$1"
export mc_ver="$2"
export srv_ver="$3"
export pkg_rel="$4"
export with_suffix="${5:-true}"

if $with_suffix; then
    export pkg_name="${srv_type}-server-${mc_ver}"
    export daemon_name="${srv_type}d-${mc_ver}"
    export srv_id="${srv_type}-${mc_ver}"
else
    export pkg_name="${srv_type}-server"
    export daemon_name="${srv_type}d"
    export srv_id="${srv_type}"
fi

export user_name="${srv_id//./-}"

envsubst '${daemon_name} ${srv_id} ${user_name}' <"${TMPLDIR}/server.install" > "${BASEDIR}/${srv_type}-server.install"
envsubst '${srv_type} ${mc_ver} ${daemon_name} ${user_name}' <"${TMPLDIR}/backup.service" > "${BASEDIR}/${daemon_name}-backup.service"
envsubst '${srv_type} ${mc_ver}' <"${TMPLDIR}/backup.timer" > "${BASEDIR}/${daemon_name}-backup.timer"
envsubst '${srv_id} ${user_name}' <"${TMPLDIR}/d.conf" > "${BASEDIR}/${daemon_name}.conf"
envsubst '${mc_ver} ${srv_type} ${daemon_name} ${user_name}' <"${TMPLDIR}/d.service" > "${BASEDIR}/${daemon_name}.service"
envsubst '${daemon_name} ${srv_id} ${user_name}' <"${TMPLDIR}/d.sh" > "${BASEDIR}/${daemon_name}.sh"
envsubst '${mc_ver} ${srv_type} ${srv_id} ${user_name}' <"${TMPLDIR}/d.sysusers" > "${BASEDIR}/${daemon_name}.sysusers"
envsubst '${srv_id} ${user_name}' <"${TMPLDIR}/d.tmpfiles" > "${BASEDIR}/${daemon_name}.tmpfiles"
env sha_backup_svc="$(sha512sum "${BASEDIR}/${daemon_name}-backup.service" | cut -d " " -f 1 )" \
    sha_backup_timer="$(sha512sum "${BASEDIR}/${daemon_name}-backup.timer" | cut -d " " -f 1 )" \
    sha_srv_svc="$(sha512sum "${BASEDIR}/${daemon_name}.service" | cut -d " " -f 1 )" \
    sha_sysusers="$(sha512sum "${BASEDIR}/${daemon_name}.sysusers" | cut -d " " -f 1 )" \
    sha_tmpfiles="$(sha512sum "${BASEDIR}/${daemon_name}.tmpfiles" | cut -d " " -f 1 )" \
    sha_conf="$(sha512sum "${BASEDIR}/${daemon_name}.conf" | cut -d " " -f 1 )" \
    sha_sh="$(sha512sum "${BASEDIR}/${daemon_name}.sh" | cut -d " " -f 1 )" \
    envsubst '${sha_backup_svc} ${sha_backup_timer} ${sha_srv_svc} ${sha_sysusers} ${sha_tmpfiles} ${sha_conf} ${sha_sh} ${pkg_rel} ${pkg_name} ${mc_ver} ${srv_ver} ${srv_type} ${srv_id} ${daemon_name}' <"${TMPLDIR}/PKGBUILD" > "${BASEDIR}/PKGBUILD"

makepkg -p "${BASEDIR}/PKGBUILD" --printsrcinfo > "${BASEDIR}/.SRCINFO"

unset srv_type
unset mc_ver
unset srv_ver
unset with_suffix
unset pkg_name
unset daemon_name
unset srv_id
