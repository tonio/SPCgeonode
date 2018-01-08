#!/bin/sh

# Exit script in case of error
set -e

printf '\n--- START Django Docker Entrypoint ---\n\n'


# TODO : move to requirements.txt (once the app is published)
# pip install git+https://github.com/PacificCommunity/geonode_offlineosm.git@master
pip install -e /offlineosm/


# Initializing Django

# disabled, you have to rebuild when we change requirements
# # Install the migrations (in case requirements.txt changed but the image was not rebuilt)
# printf '\nInstalling python requirements\n'
# pip install -r /spcnode/requirements.txt

# Wait for postgres
printf '\nWaiting for postgres...\n'
printf "import sys,time,psycopg2\n\
from spcnode.settings import DATABASE_URL\n\
while 1:\n\
  try:\n\
    psycopg2.connect(DATABASE_URL)\n\
    print('Connection to postgres successful !')\n\
    sys.exit(0)\n\
  except Exception as e:\n\
    print('Could not connect to database. Retrying in 5s')\n\
    print(str(e))\n\
    time.sleep(5)" | python -u

# Run migrations
printf '\nRunning migrations...\n'
python manage.py migrate --noinput

# Collect static
printf '\nRunning collectstatic...\n'
python manage.py collectstatic --noinput

# Createng superuser
printf '\nCreating superuser...\n'
# TODO : fix login
printf "import os, django\n\
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'spcnode.settings')\n\
django.setup()\n\
from geonode.people.models import Profile\n\
try:\n\
  user = Profile.objects.create_superuser('super','admin@test.com','duper')\n\
  print('superuser successfully created')\n\
except django.db.IntegrityError as e:\n\
  print('superuser exists already')" | python -u

# Load fixtures
printf '\nLoading initial data...\n'
python manage.py loaddata initial_data

# Creating OAuth2 data
printf "print('todo')" | python -u


# Initialize Geoserver (this waits for geonode and creates the geonode workspace if it doesn't exist)
# printf '\nWaiting for geoserver rest endpoint and creating workspace if needed\n'
# TODO : workspace name is DEFAULT_WORKSPACE
# curl -u admin:geoserver -o /dev/null -X POST -H "Content-type: text/xml" -d "<workspace><name>geonode</name></workspace>" --retry 100000 --retry-connrefused --retry-delay 5 http://nginx/geoserver/rest/workspaces

# Load fixtures
printf '\nInitialize offline osm data\n'
python manage.py updateofflineosm --no_overwrite --no_fail

# TODO : load also OAuth settings from http://docs.geonode.org/en/master/tutorials/admin/geoserver_geonode_security/

# http://127.0.0.1/geoserver
# http://127.0.0.1/geoserver/
# http://geoserver:8080/geoserver
# http://geoserver:8080/geoserver/

printf '\n--- END Django Docker Entrypoint ---\n\n'

# Run the CMD 
exec "$@"
