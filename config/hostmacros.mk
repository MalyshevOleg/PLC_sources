# Host-specific macros
#

# We have to run PATH= sudo make install on Slackware
#sudopath = $(if $(filter $(call uc,$(USE_SUDO)),TRUE),$1 sudo,$1)

# We have to run sudo PATH= make install on Ubuntu
sudopath = $(if $(filter $(call uc,$(USE_SUDO)),TRUE),sudo env $1,$1)
