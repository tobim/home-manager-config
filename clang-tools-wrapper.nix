{
  fetchFromGitHub,
  include-what-you-use,
  python3,
  stdenv,
  writeScript,
  writers,

  # Tell which _wrapped_ compiler to borrow wrapper script from
  cc
}:

let
  clang-tools-extra = fetchFromGitHub {
    owner = "llvm-mirror";
    repo = "clang-tools-extra";
    rev = "c8e49d231cbb873ef848d7bf1fb4585bc018e924";
    sha256 = "1m4rss6k66pnjdx0q8v02aniyjhx6lsmf0vvf4ay9f0vqjkm43ws";
  };
  cpp-convert = writers.writePython3 "compile-command-convert" {} ''
    import json
    import subprocess


    def read(filename):
        with open(filename) as json_file:
            return json.load(json_file)


    def write(filename, data):
        with open(filename, 'w') as outfile:
            json.dump(data, outfile)


    def fix(command_str):
        head, *tail = command_str.split()
        cmd = "c++-echo-wrapper {}".format(' '.join(tail))
        fixed = subprocess.check_output(cmd, shell=True).decode()[:-1]
        return head + ' ' + fixed


    FILENAME = 'compile_commands.json'

    doc = read(FILENAME)

    for item in doc:
        item['command'] = fix(item['command'])

    write(FILENAME, doc)
  '';
  clang-tidy-wrapper = writers.writePython3 "clang-tidy-wrapper" {} ''
    import subprocess
    import sys


    def split_index(l):
        for idx, val in enumerate(l):
            if val == '--':
                return idx
        return -1


    cc = '${cc.cc}'
    wrapped_ctidy = [(cc + '/bin/clang-tidy')]
    dashdash_position = split_index(sys.argv)
    if dashdash_position != -1:
        clang_tidy_wrapper, *normal_args = sys.argv[:dashdash_position]
        cc, *args = sys.argv[dashdash_position + 1:]
        fixed = subprocess.check_output(['c++-echo-wrapper'] + args).decode()
        result = wrapped_ctidy + normal_args + ['--', cc] + fixed.split()
    else:
        result = wrapped_ctidy + sys.argv[1:]
    subprocess.run(result)
  '';

in stdenv.mkDerivation {
  name = "clang-tools-wrappers";
  preferLocalBuild = true;
  builder = writeScript "builder" ''
    source $stdenv/setup
    mkdir -p $out/bin/ $out/nix-support

    echo "${cc}" > $out/nix-support/cc

    # This wrapper will simply print the unwrapped parameters
    sed 's;^exec /nix/store/.*;echo \\;' ${cc}/bin/c++ > $out/bin/c++-echo-wrapper
    chmod +x $out/bin/c++-echo-wrapper

    # This tool can convert a compile_commands.json file to unwrapped params
    cp ${cpp-convert} $out/bin/compile-command-convert

    # Everything that clang-tidy gets after the "--" param is unwrapped
    cp ${clang-tidy-wrapper} $out/bin/clang-tidy-wrapper
    ln -sf $out/bin/clang-tidy-wrapper $out/bin/clang-tidy

    # Wrapper for include-what-you-use
    sed "s;^exec[^\\]*;exec ${include-what-you-use}/bin/include-what-you-use ;" ${cc}/bin/c++ > $out/bin/include-what-you-use
    chmod +x $out/bin/include-what-you-use

    # This is just a useful script that is missing in the normal clang package
    # Can be run after running compile-command-convert
    cp ${clang-tools-extra}/clang-tidy/tool/run-clang-tidy.py $out/bin
    PATH=${python3}/bin:$PATH patchShebangs $out/bin/run-clang-tidy.py

    for tool in clang-apply-replacements clang-check clang-format clang-rename clangd
    do
      ln -s ${cc.cc}/bin/$tool $out/bin/$tool
    done

    #makeWrapper ${cc.cc}/bin/clang-include-fixer "$out/bin/clang-include-fixer" \
    #  -add-flags "--extra-args=$$NIX_CFLAGS_COMPILE"
  '';

  meta = with stdenv.lib; {
    description = "NixOS-specific wrappers around clang tooling";
    homepage = https://github.com/tfc/nur-packages;
    # We're repacking the run-clang-tidy.py script, so this license
    # seems most correct
    license = licenses.asl20;
  };
}

