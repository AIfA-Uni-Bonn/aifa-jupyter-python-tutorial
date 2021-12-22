# written: 2019-06-18
# changed: 2021-11-

# Software:
# - jupyterlab 3.2.4
# - numpy      latest
# - scipy      latest
# - kafe2      >2.4.0


# taking the latest image

# Nov 20 2021
FROM jupyter/minimal-notebook:2021-11-20


# Mar 29 2021
#FROM jupyter/minimal-notebook:4d9c9bd9ced0
#FROM jupyter/minimal-notebook:12ba1d59fbc3

## July 13 2020 
#FROM jupyter/minimal-notebook:ea01ec4d9f57

## Sep. 11 2019
#FROM jupyter/minimal-notebook:1386e2046833  

# inspired by: 
# https://github.com/umsi-mads/education-notebook/blob/master/Dockerfile 



LABEL maintainer="AIfA Jupyter Project <ocordes@astro.uni-bonn.de>"


# Do here all steps as root
USER root

RUN chgrp users /etc/passwd
RUN echo "nbgrader:x:2000:" >> /etc/group

# run the unminimizer
COPY  unminimize.aifa /usr/local/sbin/unminimize.aifa
RUN chmod 755 /usr/local/sbin/unminimize.aifa
RUN unminimize.aifa

# fix the BUG in Ubuntu focal image
#RUN sed -i '/path-exclude=\/usr\/share\/man\/*/c\#path-exclude=\/usr\/share\/man\/*' /etc/dpkg/dpkg.cfg.d/excludes
RUN   apt-get -qq update && \
  apt-get install --yes --no-install-recommends man manpages-posix

# necessary for apt-key
RUN apt update
RUN apt-get install -y gnupg2

# add ownloud
RUN sh -c "echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_20.04/ /' > /etc/apt/sources.list.d/isv:ownCloud:desktop.list"
RUN wget -nv https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_20.04/Release.key -O Release.key

RUN apt-key add - < Release.key


# add sciebo
RUN wget -nv https://www.sciebo.de/install/linux/Ubuntu_20.04/Release.key -O - | apt-key add -
RUN echo 'deb https://www.sciebo.de/install/linux/Ubuntu_20.04/ /' | tee -a /etc/apt/sources.list.d/sciebo.list


# Run assemble scripts! These will actually build the specification
# in the repository into the image.
RUN apt-get -qq update && \
  apt-get install --yes --no-install-recommends openssh-client  \
        less \
	inotify-tools \
	owncloud-client \	
        sciebo-client \
        sextractor \
        scamp \
        swarp \
	zip \
	iputils-ping \
        texlive-latex-base \
	texlive-latex-recommended \
	texlive-science \
	texlive-latex-extra \
	texlive-fonts-recommended \
 	texlive-lang-german \
	texlive-bibtex-extra \
	texlive-extra-utils \
	texlive-fonts-extra \
	texlive-fonts-extra-links \
	texlive-fonts-recommended \
	texlive-formats-extra \
	texlive-humanities \
	texlive-luatex \
	texlive-metapost \
	texlive-pictures \
	texlive-pstricks \
	texlive-publishers \
        cm-super \
	biber \
	lmodern \
	dvipng \
	ghostscript \
        latexmk \
        ffmpeg \
	imagemagick && \
  apt-get install --yes --no-install-recommends manpages man-db coreutils lsb-release lsb-core nano vim emacs tree  && \
  apt-get -qq purge && \
  apt-get -qq clean && \
  rm -rf /var/lib/apt/lists/*

COPY policy.xml /etc/ImageMagick-6/

## handling nodejs, since all versions from conda and ubuntu itself
## are outdated
#RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
##RUN apt-get update
#RUN apt-get install -y nodejs



# use this for debugging in the case of UID/GID problems
COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

# switch back to jovyan to install conda packages

USER $NB_UID


# The conda-forge channel is already present in the system .condarc file, so there is no need to
# add a channel invocation in any of the next commands.

# install jupyterlab
RUN conda install jupyterlab=3.2.4  --yes

#RUN conda install jupyterhub --yes

# Add nbgrader 0.6.1 to the image
# More info at https://nbgrader.readthedocs.io/en/stable/

#RUN conda install nbgrader=0.6.1 --yes


# Add the notebook extensions
RUN conda install jupyter_contrib_nbextensions --yes

# Add RISE 5.4.1 to the mix as well so user can show live slideshows from their notebooks
# More info at https://rise.readthedocs.io
# Note: Installing RISE with --no-deps because all the neeeded deps are already present.
RUN conda install rise --no-deps --yes


# Add the science packages for AIfA
RUN conda install numpy matplotlib scipy astropy sympy scikit-image scikit-learn seaborn colorama pandas pyhdf h5py pydub --yes


# Add kafe for python fitting
RUN pip install kafe2
RUN pip install 'iminuit>2'
RUN pip install PhyPraKit


# Add meteostat package
RUN pip install meteostat


# add extensions by conda
RUN conda install ipywidgets ipyevents ipympl jupyterlab_latex --yes
RUN conda install version_information jupyter-archive jupyterlab-git --yes

# remove all unwanted stuff
RUN conda clean -a -y


# handling nodejs, since all versions from conda and ubuntu itself
# are outdated
##RUN conda uninstall nodejs --yes




# jupyterlab extensions

# topbar / logout button
RUN pip install jupyterlab-topbar
RUN pip install jupyterlab-logout

# memory display in bottom line
RUN conda install nbresuse

# theme toggling extension
RUN jupyter labextension install jupyterlab-theme-toggle --no-build

# interactive widgets
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build

# matplotlib extension
RUN jupyter labextension install jupyter-matplotlib@ --no-build

# jupyter classic extensions
RUN jupyter nbextension enable --py widgetsnbextension


# jupyterlab tocs
#RUN jupyter labextension install @jupyterlab/toc --no-build

# jupyterlab variable inspector
#RUN jupyter labextension install @lckr/jupyterlab_variableinspector --no-build

# compile all extensions
RUN jupyter lab build --debug

#RUN jupyter serverextension enable --sys-prefix jupyterlab_latex


# install the spellchecker
RUN pip install jupyterlab-spellchecker

# install latex extension
RUN pip install jupyterlab-latex

# apply the latex configuration

RUN echo "" >> /etc/jupyter/jupyter_notebook_config.py
RUN echo "c.LatexConfig.latex_command = 'pdflatex'" >> /etc/jupyter/jupyter_notebook_config.py
RUN echo "c.LatexConfig.bib_command = 'biber'" >> /etc/jupyter/jupyter_notebook_config.py
RUN echo "c.LatexConfig.run_times = 2" >> /etc/jupyter/jupyter_notebook_config.py

# copy the generell nbgrader configuration
#COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py


# install additional kernels
RUN pip install calysto_bash

# install javascript/Typescript kernel
#RUN conda install nodejs
#RUN which npm
RUN npm install  tslab
#RUN which npm
#RUN find / -name "*tslab*"
#RUN which tslab
# RUN /opt/conda/node_modules/tslab/bin/tslab install --prefix /opt/conda


# add the jupyter XFCE desktop
USER root

RUN apt-get -y update \
 && apt-get install -y dbus-x11 \
   firefox \
   xfce4 \
   xfce4-panel \
   xfce4-session \
   xfce4-settings \
   xorg \
   xubuntu-icon-theme \
 && apt-get -qq clean \
 && rm -rf /var/lib/apt/lists/*

# Remove light-locker to prevent screen lock
ARG TURBOVNC_VERSION=2.2.6
RUN wget -q "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get install -y -q ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get remove -y -q light-locker && \
   rm ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   ln -s /opt/TurboVNC/bin/* /usr/local/bin/

# apt-get may result in root-owned directories/files under $HOME
RUN chown -R $NB_UID:$NB_GID $HOME

USER $NB_UID

RUN conda install jupyter-server-proxy>=1.4 websockify

RUN pip install https://github.com/jupyterhub/jupyter-remote-desktop-proxy/archive/refs/heads/main.zip
# Done.
