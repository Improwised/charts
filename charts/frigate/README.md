# frigate



NVR With Realtime Object Detection for IP Cameras

This Helm Chart installs [Frigate](https://frigate.video/) on to Kubernetes.

**Homepage:** helm repo index --url https://improwised.github.io/charts .
## Install

Using [Helm](https://helm.sh), you can easily install and test Frigate in a
Kubernetes cluster by running the following:

#### Add Helm repo

First, add the repo if you haven't already done so:
```bash
helm repo add improwised https://improwised.github.io/charts/
```

#### Minimum Config

At minimum, you'll need to define the following Frigate configuration properties. For information, see the [Docs](https://docs.frigate.video/configuration/index).

```yaml
# values.yaml
config: |
  mqtt:
    host: "mqtt.example.com"
    port: 1883
    user: admin
    password: "<your_mqtt_password>"
  cameras:
    # Define at least one camera
    back:
      ffmpeg:
        inputs:
          - path: rtsp://viewer:{FRIGATE_RTSP_PASSWORD}@10.0.10.10:554/cam/realmonitor?channel=1&subtype=2
            roles:
              - detect
              - rtmp
      detect:
        width: 1280
        height: 720
```

#### Install Chart

Now install the chart:
```bash
helm upgrade --install \
  my-release \
  improwised/frigate \
  -f values.yaml
```

## Maintainers

| Name | URL
| ---- | ------ 
| Improwised | improwised.com |




