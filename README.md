# Creation of a docker image for nextsimdg with intel compilers

All I need is a :
  - [Dockerfile](Dockerfile)
  - [github action](.github/workflows/build.yaml) that will build the image each time I modify the Dockerfile in which I put IMAGE_NAME corresponding to a repo I created for it in my quay account
  - the QUAY_USERNAME and QUAY_PASSWORD in github secrets are filled with values obtained in quay by creating a robot account
