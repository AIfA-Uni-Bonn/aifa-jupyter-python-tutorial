# written: 2019-06-18

# taking the latest image
# Sep. 11 2019
FROM jupyter/minimal-notebook:1386e2046833  
#FROM jupyter/minimal-notebook:d4cbf2f80a2a 

# inspired by: 
# https://github.com/umsi-mads/education-notebook/blob/master/Dockerfile 

# Do here all steps as root
USER root

RUN chgrp users /etc/passwd
RUN echo "nbgrader:x:2000:" >> /etc/group

#RUN apt install less

# fix the BUG in Ubuntu bionic image
RUN sed -i '/path-exclude=\/usr\/share\/man\/*/c\#path-exclude=\/usr\/share\/man\/*' /etc/dpkg/dpkg.cfg.d/excludes && \
  apt-get -qq update && \
  apt-get install --yes --no-install-recommends man manpages-posix && \
  dpkg -l | grep ^ii | cut -d' ' -f3 | xargs apt-get install -y --reinstall && \
  apt-get -qq purge && \
  apt-get -qq clean


# Run assemble scripts! These will actually build the specification
# in the repository into the image.
RUN apt-get -qq update && \
  apt-get install --yes --no-install-recommends openssh-client  \
        less \
        texlive-latex-base \
	texlive-latex-recommended \
	texlive-science \
	texlive-latex-extra \
	texlive-fonts-recommended \
 	texlive-lang-german \
	lmodern \
	dvipng \
	ghostscript && \
  apt-get install --yes --no-install-recommends manpages man-db coreutils lsb-release lsb-core nano vim emacs tree  && \
  apt-get -qq purge && \
  apt-get -qq clean && \
  rm -rf /var/lib/apt/lists/*


# use this for debugging in the case of UID/GID problems
COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

# switch back to jovyan to install conda packages

USER $NB_UID


# The conda-forge channel is already present in the system .condarc file, so there is no need to
# add a channel invocation in any of the next commands.

# Add nbgrader 0.5.5 to the image
# More info at https://nbgrader.readthedocs.io/en/stable/

RUN conda install nbgrader --yes


# Add the notebook extensions
RUN conda install jupyter_contrib_nbextensions --yes

# Add RISE 5.4.1 to the mix as well so user can show live slideshows from their notebooks
# More info at https://rise.readthedocs.io
# Note: Installing RISE with --no-deps because all the neeeded deps are already present.
RUN conda install rise --no-deps --yes


# Add the science packages for AIfA
RUN conda install numpy matplotlib scipy astropy sympy --yes 


RUN conda install scikit-image scikit-learn seaborn --yes

COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py

RUN conda install -y nodejs --yes
RUN pip install ipympl jupyterlab_latex

# remove all unwanted stuff
RUN conda clean -a -y

# enable top buttons for jupyter lab
RUN jupyter labextension install @fissio/hub-topbar-buttons --no-build


RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build 
RUN jupyter labextension install jupyter-matplotlib --no-build
RUN jupyter nbextension enable --py widgetsnbextension

RUN jupyter labextension install @jupyterlab/latex  --no-build
RUN jupyter lab build
# RUN jupyter serverextension enable --sys-prefix jupyterlab_latex

RUN echo "c.LatexConfig.latex_command = 'pdflatex'" >> /etc/jupyter/jupyter_notebook_config.py
