# In case there is an external EBS volume available, 
# this state file will format it and make it available on /ext
# (customizable with pillar.elife.external_volume.directory)
# In Vagrant, this falls back to just be an empty /ext directory
# on the same device as `/`

format-external-volume:
    cmd.run: 
        - name: mkfs -t {{ pillar.elife.external_volume.filesystem }} {{ pillar.elife.external_volume.device }}
        - onlyif:
            # disk exists
            - test -b {{ pillar.elife.external_volume.device }}
        - unless:
            # volume exists and is already formatted
            - file --special-files {{ pillar.elife.external_volume.device }} | grep {{ pillar.elife.external_volume.filesystem }}

mount-point-external-volume:
    file.directory:
        - name: {{ pillar.elife.external_volume.directory }}

mount-external-volume:
    mount.mounted:
        - name: {{ pillar.elife.external_volume.directory }}
        - device: {{ pillar.elife.external_volume.device }}
        - fstype: {{ pillar.elife.external_volume.filesystem }}
        - mkmnt: True
        - opts:
            - defaults
        - require:
            - format-external-volume
            - mount-point-external-volume
        - onlyif:
            # disk exists
            - test -b {{ pillar.elife.external_volume.device }}
        - unless:
            # mount point already has a volume mounted
            - cat /proc/mounts | grep --quiet --no-messages {{ pillar.elife.external_volume.directory }}

tmp-directory-on-external-volume:
    file.directory:
        - name: /ext/tmp
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - mount-external-volume
        - require_in:
            - new-ubr-config # builder-base-formula.backups

