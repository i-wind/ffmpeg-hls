## Setup

Prepare virtual environment

    $ virtualenv --no-site-packages ~/.pyenv/ffmpeg
    $ source ~/.pyenv/ffmpeg/bin/activate
    $ pip install setuptools --upgrade
    $ pip install pip --upgrade
    $ pip install fabric
    $ pip freeze >require.txt
    $ pip install tornado==4.3

Install development packages

    $ pip install -r require.txt
