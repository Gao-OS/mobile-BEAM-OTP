defmodule MobileRuntimes do
  require EEx

  def cmd(args, env \\ []) do
    args = if is_list(args), do: Enum.join(args, " "), else: args

    env =
      Enum.map(env, fn {key, value} ->
        case key do
          atom when is_atom(atom) -> {Atom.to_string(atom), value}
          _other -> {key, value}
        end
      end)

    IO.puts("RUN: #{args}")

    {ret, 0} =
      System.cmd("bash", ["-c", args],
        stderr_to_stdout: true,
        into: IO.binstream(:stdio, :line),
        env: env
      )

    ret
  end

  def docker_build(image, file) do
    IO.puts("RUN: docker build -t #{image} -f #{file} .")

    ret =
      System.cmd("docker", ~w(build -t #{image} -f #{file} .),
        stderr_to_stdout: true,
        into: IO.binstream(:stdio, :line)
      )

    File.rm(file)
    {_, 0} = ret
  end

  def default_nifs() do
    [
      "https://github.com/diodechain/esqlite.git",
      "https://github.com/elixir-desktop/exqlite",
      "https://github.com/diodechain/libsecp256k1.git"
    ]
  end

  def get_nif(url) when is_binary(url) do
    get_nif({url, []})
  end

  def get_nif({url, opts}) do
    name = Keyword.get(opts, :name, Path.basename(url, ".git"))
    tag = Keyword.get(opts, :tag, nil)

    %{
      tag: tag,
      repo: url,
      name: name,
      basename: Path.basename(url, ".git")
    }
  end

  def otp_source() do
    System.get_env("OTP_SOURCE", "https://github.com/erlang/otp")
  end

  def otp_tag() do
    System.get_env("OTP_TAG", "OTP-28.3")
  end

  def ensure_otp() do
    if !File.exists?("_build/otp") do
      File.mkdir_p!("_build")

      cmd(
        "git clone #{MobileRuntimes.otp_source()} _build/otp && cd _build/otp && git checkout #{MobileRuntimes.otp_tag()}"
      )
    end

    # Apply patches if not already done (supports actions/checkout pre-cloned OTP)
    if !File.exists?("_build/otp/.mobile_patched") do
      apply_otp_patches()
      File.write!("_build/otp/.mobile_patched", "true")
    end
  end

  def apply_otp_patches() do
    patches = Path.wildcard("patch/otp-*.patch")

    if Enum.empty?(patches) do
      IO.puts("No OTP patches to apply (all fixes upstream in this OTP version)")
    else
      for patch <- patches do
        IO.puts("Applying patch: #{patch}")
        cmd("cd _build/otp && git apply ../../#{patch}")
      end

      # Commit patches so clones inherit them (configure git user for CI environments)
      cmd("cd _build/otp && git config user.email 'build@mobile-beam.local' && git config user.name 'Mobile BEAM Build'")
      cmd("cd _build/otp && git add -A && git commit -m 'Apply mobile patches'")
    end
  end

  def erts_version() do
    ensure_otp()
    content = File.read!("_build/otp/erts/vsn.mk")
    [[_, vsn]] = Regex.scan(~r/VSN *= *([0-9\.]+)/, content)
    vsn
  end

  def install_program() do
    case :os.type() do
      {:unix, :linux} -> "/usr/bin/install -c -s --strip-program=llvm-strip"
      {:unix, :darwin} -> "/usr/bin/install -c"
    end
  end

  def host() do
    case :os.type() do
      {:unix, :linux} -> "linux-x86_64"
      {:unix, :darwin} -> "darwin-x86_64"
    end
  end

  def elixir_target(arch) do
    Path.absname("_build/#{arch.name}/elixir")
  end

  def stub_target(arch) do
    Path.absname("_build/#{arch.name}/stubs")
  end

  def static_lib_path(arch, nif) do
    nif_dir = "_build/#{arch.name}/#{nif.basename}"

    # Finding all .a files
    :filelib.fold_files(
      String.to_charlist(nif_dir),
      ~c".+\\.a$",
      true,
      fn name, acc -> [List.to_string(name) | acc] end,
      []
    )
    |> Enum.filter(fn path -> String.contains?(path, "priv") end)
    |> List.first()
  end

  def openssl_target(arch) do
    Path.absname("_build/#{arch.name}/openssl")
  end

  def openssl_lib(arch) do
    Path.join(openssl_target(arch), "lib/libcrypto.a")
  end

  def otp_target(arch) do
    Path.absname("_build/#{arch.name}/otp")
  end

  def runtime_target(arch) do
    "_build/#{arch.name}/liberlang.a"
  end

  #  Method takes multiple ".a" archive files and extracts their ".o" contents
  # to then reassemble all of them into a single `target` ".a" archive
  #  Method takes multiple ".a" archive files and extracts their ".o" contents
  # to then reassemble all of them into a single `target` ".a" archive
  def repackage_archive(libtool, files, target, env \\ []) do
    # Removing relative prefix so changing cwd is safe.
    files = Enum.join(files, " ")
    cmd("#{libtool} -static -o #{target} #{files}", env)
  end
end
