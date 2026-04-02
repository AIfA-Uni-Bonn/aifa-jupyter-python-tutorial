# written: 2019-06-18
# changed: 2022-11-14

# Software:
# - jupyterlab 3.3.2
# - numpy      latest
# - scipy      latest
# - kafe2      >2.4.0


# taking the latest image


# April 01 2026
FROM quay.io/jupyter/minimal-notebook:python-3.13.12

# Mar 21 2022
#FROM jupyter/minimal-notebook:2022-03-21

# Nov 20 2021
#FROM jupyter/minimal-notebook:2021-11-20


# inspired by: 
# https://github.com/umsi-mads/education-notebook/blob/master/Dockerfile 



LABEL maintainer="AIfA Jupyter Project <ocordes@astro.uni-bonn.de>"


# Do here all steps as root
USER root

RUN chgrp users /etc/passwd
RUN echo "nbgrader:x:2000:" >> /etc/group

# run the unminimizer
COPY  files/unminimize.aifa /usr/local/sbin/unminimize.aifa
RUN chmod 755 /usr/local/sbin/unminimize.aifa
RUN unminimize.aifa

# fix the BUG in Ubuntu focal image
#RUN sed -i '/path-exclude=\/usr\/share\/man\/*/c\#path-exclude=\/usr\/share\/man\/*' /etc/dpkg/dpkg.cfg.d/excludes

RUN   apt-get -qq update && \
  apt-get install --yes --no-install-recommends man manpages-posix gnupg2 software-properties-common

# add firefox
RUN add-apt-repository ppa:mozillateam/ppa
COPY files/mozilla-firefox /etc/apt/preferences.d/mozilla-firefox

COPY apt.txt /tmp
RUN apt-get -qq update && \
    apt-get install --yes --no-install-recommends $(cat /tmp/apt.txt) && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* && rm -f /tmp/apt.txt

COPY files/policy.xml /etc/ImageMagick-6/


# install Visual Studio Code
RUN wget "https://packages.microsoft.com/repos/code/pool/main/c/code/code_1.104.1-1758154125_amd64.deb" && \
    apt install ./code_*_amd64.deb && \
    rm -f ./code_*_amd64.deb


# install PyCharm community
RUN wget "https://download.jetbrains.com/python/pycharm-community-2025.2.2.tar.gz" && \
    tar -C /opt -xvf ./pycharm-community-2025.2.2.tar.gz && \
    (cd /usr/local/bin; ln -s /opt/pycharm-community-2025.2.2/bin/pycharm.sh pycharm) && \
    cp /opt/pycharm-community-2025.2.2/bin/pycharm.png  /usr/share/pixmaps  && \
    rm -f ./pycharm-community-2025.2.2.tar.gz
COPY files/pycharm.desktop /usr/share/applications/pycharm.desktop


# Remove light-locker to prevent screen lock
ARG TURBOVNC_VERSION=2.2.6
RUN wget -q "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get install -y -q ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get remove -y -q light-locker && \
   rm ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   ln -s /opt/TurboVNC/bin/* /usr/local/bin/


RUN rm -rf /home/jovyan/.launchpadlib



# use this for debugging in the case of UID/GID problems
RUN chgrp users /etc/passwd
COPY files/start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

# switch back to jovyan to install conda packages

USER $NB_UID


#Kopiere die lokalen Dateien conda_env.yml und pip_env.txt in das Image hinein
COPY --chown=jovyan:users conda_env.yml pip_env.txt /tmp/

#Installation der conda-Umgebung mit mamba
RUN mamba update -n base mamba &&\
    mamba env update -n base -f /tmp/conda_env.yml &&\
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

#Installation der pip-Umgebung
RUN pip install --no-cache-dir -r /tmp/pip_env.txt


# install jupyterlab
#RUN mamba install jupyterlab=3.3.2  --yes && \
#	# Add nbgrader 0.6.1 to the image
#	# More info at https://nbgrader.readthedocs.io/en/stable/
#        # conda install nbgrader=0.6.1 --yes &6 \
#	# Add the notebook extensions
#	mamba install jupyter_contrib_nbextensions --yes && \

#	# Add RISE 5.4.1 to the mix as well so user can show live slideshows from their notebooks
#	# More info at https://rise.readthedocs.io
#	# Note: Installing RISE with --no-deps because all the neeeded deps are already present.
#	mamba install rise --no-deps --yes && \


#	# Add the science packages for AIfA
#	mamba install numpy matplotlib==3.5.2 scipy astropy sympy scikit-image scikit-learn seaborn colorama pandas pyhdf h5py pydub --yes && \

#	# Add kafe for python fitting
#	pip install kafe2 'iminuit>2' PhyPraKit && \

#	# Add meteostat package
#	pip install meteostat && \

#	# add extensions by conda
#	mamba install ipywidgets ipyevents ipympl jupyterlab_latex --yes && \
#	mamba install version_information jupyter-archive>=3.3.0 jupyterlab-git --yes && \

#	# jupyterlab extensions

#	# topbar / logout button
#	pip install jupyterlab-topbar jupyterlab-logout && \

#	# memory display in bottom line
#	mamba install nbresuse && \

#	# theme toggling extension
#	# interactive widgets
#	# matplotlib extension
#	# jupyter classic extensions

#       jupyter labextension install jupyterlab-theme-toggle @jupyter-widgets/jupyterlab-manager jupyter-matplotlib@ --no-build && \
#	jupyter nbextension enable --py widgetsnbextension && \


#	# jupyterlab tocs
#	#jupyter labextension install @jupyterlab/toc --no-build && \

#	# jupyterlab variable inspector
#	#jupyter labextension install @lckr/jupyterlab_variableinspector --no-build && \

#	# compile all extensions
#	jupyter lab build --debug && \


#	# install the spellchecker
#	pip install jupyterlab-spellchecker jupyterlab-latex && \

#	# apply the latex configuration

#	echo "" >> /etc/jupyter/jupyter_notebook_config.py && \
#	echo "c.LatexConfig.latex_command = 'pdflatex'" >> /etc/jupyter/jupyter_notebook_config.py && \
#	echo "c.LatexConfig.bib_command = 'biber'" >> /etc/jupyter/jupyter_notebook_config.py && \
#	echo "c.LatexConfig.run_times = 2" >> /etc/jupyter/jupyter_notebook_config.py && \

#	# copy the generell nbgrader configuration
#	#COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py


#	# install additional kernels
#	pip install calysto_bash && \

#	# install spyder
#	mamba install spyder && \

#	# remove all unwanted stuff
#	mamba clean -a -y


RUN jupyter nbextension enable --py widgetsnbextension && \
    # jupyter labextension install jupyterlab-theme-toggle && \
    #jupyter labextension @jupyter-widgets/jupyterlab-manager jupyter-matplotlib@ --no-build && \
    \
    # build all extensions
    jupyter lab build


# overwrite the startup script
COPY files/xstartup /opt/conda/lib/python3.13/site-packages/jupyter_desktop/share/

# Update der astrometry-net-Konfiguration
COPY files/astrometry.cfg /opt/conda/etc/astrometry.cfg
COPY files/astrometry.cfg /opt/conda/share/astrometry/astrometry.cfg


#Entferne die lokalen Dateien wieder aus dem Image
RUN rm -f /tmp/pip_env.txt /tmp/conda_env.yml


# test configuration for the praktikum physik 2022-10--15
#RUN mamba install lmfit && \
#    # remove all unwanted stuff
#    mamba clean -a -y
#RUN pip install git+https://github.com/proplot-dev/proplot.git


# lensing stuff
#RUN mamba install astroquery \
#     pyccl \
#     galsim \
#     camb \
#     treecorr && \
#    mamba clean -a -y
#RUN pip install colossus lenstools


# Done.
