export HOMEBREW_NO_AUTO_UPDATE=1

export NVM_DIR="/Users/$(whoami)/goinfre/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export HOMEBREW_CASK_OPTS="--appdir=/Users/$(whoami)/goinfre/Applications"

export ANDROID_NDK_HOME="/opt/goinfre/$(whoami)/homebrew/share/android-ndk"

export OLLAMA_MODELS=/goinfre/$(whoami)/ollama/models

# Android в goinfre
export GRADLE_USER_HOME=/opt/goinfre/$(whoami)/.gradle

export DOTNET_ROOT=/opt/goinfre/$(whoami)/dotnet

export ANDROID_HOME=/Users/$(whoami)/goinfre/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH