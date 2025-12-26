defmodule MobileRuntimes.Ios do
  import MobileRuntimes

  def architectures() do
    # Only arm64 supported - armv7 (32-bit) dropped since iOS 11
    %{
      "ios-arm64" => %{
        arch: "arm64",
        id: "ios64",
        sdk: "iphoneos",
        openssl_arch: "ios64-xcrun",
        xcomp: "arm64-ios",
        name: "aarch64-apple-ios",
        cflags: "-mios-version-min=12.0 -fno-common -Os -D__IOS__=yes"
      },
      "iossimulator-x86_64" => %{
        arch: "x86_64",
        id: "iossimulator",
        sdk: "iphonesimulator",
        openssl_arch: "iossimulator-x86_64-xcrun",
        xcomp: "x86_64-iossimulator",
        name: "x86_64-apple-iossimulator",
        cflags: "-mios-simulator-version-min=12.0 -fno-common -Os -D__IOS__=yes"
      },
      "iossimulator-arm64" => %{
        arch: "arm64",
        id: "iossimulator",
        sdk: "iphonesimulator",
        openssl_arch: "iossimulator-arm64-xcrun",
        xcomp: "arm64-iossimulator",
        name: "aarch64-apple-iossimulator",
        cflags: "-mios-simulator-version-min=12.0 -fno-common -Os -D__IOS__=yes"
      }
    }
  end

  def get_arch(arch) do
    Map.fetch!(architectures(), arch)
  end

  # lipo joins different cpu build of the same target together
  def lipo([]), do: []
  def lipo([one]), do: [one]

  def lipo(more) do
    File.mkdir_p!("tmp")
    x = System.unique_integer([:positive])
    tmp = "tmp/#{x}-liberlang.a"
    if File.exists?(tmp), do: File.rm!(tmp)
    cmd("lipo -create #{Enum.join(more, " ")} -output #{tmp}")
    [tmp]
  end
end
