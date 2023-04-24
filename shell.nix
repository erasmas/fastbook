let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};

  # This is the Python version that will be used.
  python = pkgs.python3;

  pythonWithPkgs = python.withPackages (pythonPkgs: with pythonPkgs; [
    # This list contains tools for Python development.
    # You can also add other tools, like black.
    #
    # Note that even if you add Python packages here like PyTorch or Tensorflow,
    # they will be reinstalled when running `pip -r requirements.txt` because
    # virtualenv is used below in the shellHook.
    ipython
    pip
    setuptools
    virtualenvwrapper
    wheel
  ]);

  lib-path = with pkgs; lib.makeLibraryPath [
    libffi
    openssl
    stdenv.cc.cc
  ];
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    pythonWithPkgs
    # other packages needed for compiling python libs
    pkgs.readline
    pkgs.libffi
    pkgs.openssl

    # unfortunately needed because of messing with LD_LIBRARY_PATH below
    pkgs.git
    pkgs.openssh
    pkgs.rsync
  ];

  shellHook = ''
    # Allow the use of wheels.
    SOURCE_DATE_EPOCH=$(date +%s)
    # Augment the dynamic linker path
    export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${lib-path}"
    # Setup the virtual environment if it doesn't already exist.
    VENV=.venv
    if test ! -d $VENV; then
      virtualenv $VENV
    fi
    source ./$VENV/bin/activate.fish
    export PYTHONPATH=`pwd`/$VENV/${python.sitePackages}/:$PYTHONPATH
  '';
}
