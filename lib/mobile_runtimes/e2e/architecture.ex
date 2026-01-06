defmodule MobileRuntimes.E2E.Architecture do
  @moduledoc """
  Supported target architectures for E2E testing.

  Provides mapping between atom representations and platform-specific identifiers
  used by Android NDK (ABI names) and iOS (destination identifiers).
  """

  @type t ::
          :android_armeabi_v7a
          | :android_arm64_v8a
          | :android_x86_64
          | :ios_arm64
          | :ios_arm64_simulator
          | :ios_x86_64_simulator

  @android_archs [:android_armeabi_v7a, :android_arm64_v8a, :android_x86_64]
  @ios_archs [:ios_arm64, :ios_arm64_simulator, :ios_x86_64_simulator]
  @all_archs @android_archs ++ @ios_archs

  @doc """
  Returns all supported architectures.
  """
  @spec all() :: [t()]
  def all, do: @all_archs

  @doc """
  Returns all Android architectures.
  """
  @spec android() :: [t()]
  def android, do: @android_archs

  @doc """
  Returns all iOS architectures.
  """
  @spec ios() :: [t()]
  def ios, do: @ios_archs

  @doc """
  Returns the platform for an architecture.
  """
  @spec platform(t()) :: :android | :ios
  def platform(arch) when arch in @android_archs, do: :android
  def platform(arch) when arch in @ios_archs, do: :ios

  @doc """
  Returns true if the architecture is a simulator/emulator.
  """
  @spec emulator?(t()) :: boolean()
  def emulator?(:android_x86_64), do: true
  def emulator?(:ios_arm64_simulator), do: true
  def emulator?(:ios_x86_64_simulator), do: true
  def emulator?(_), do: false

  @doc """
  Converts architecture atom to Android ABI name or iOS destination identifier.
  """
  @spec to_string(t()) :: String.t()
  def to_string(:android_armeabi_v7a), do: "armeabi-v7a"
  def to_string(:android_arm64_v8a), do: "arm64-v8a"
  def to_string(:android_x86_64), do: "x86_64"
  def to_string(:ios_arm64), do: "arm64"
  def to_string(:ios_arm64_simulator), do: "arm64-simulator"
  def to_string(:ios_x86_64_simulator), do: "x86_64-simulator"

  @doc """
  Parses a string into an architecture atom.

  ## Examples

      iex> MobileRuntimes.E2E.Architecture.parse("android-arm64-v8a")
      {:ok, :android_arm64_v8a}

      iex> MobileRuntimes.E2E.Architecture.parse("invalid")
      {:error, :invalid_architecture}
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, :invalid_architecture}
  def parse("android-armeabi-v7a"), do: {:ok, :android_armeabi_v7a}
  def parse("android-arm64-v8a"), do: {:ok, :android_arm64_v8a}
  def parse("android-x86_64"), do: {:ok, :android_x86_64}
  def parse("ios-arm64"), do: {:ok, :ios_arm64}
  def parse("ios-arm64-simulator"), do: {:ok, :ios_arm64_simulator}
  def parse("ios-x86_64-simulator"), do: {:ok, :ios_x86_64_simulator}
  def parse(_), do: {:error, :invalid_architecture}

  @doc """
  Parses a string into an architecture atom, raising on invalid input.
  """
  @spec parse!(String.t()) :: t()
  def parse!(str) do
    case parse(str) do
      {:ok, arch} -> arch
      {:error, :invalid_architecture} -> raise ArgumentError, "Invalid architecture: #{str}"
    end
  end

  @doc """
  Returns the liberlang path for an architecture.
  """
  @spec liberlang_path(t()) :: String.t()
  def liberlang_path(arch) when arch in @android_archs do
    "_build/#{__MODULE__.to_string(arch)}/liberlang.a"
  end

  def liberlang_path(_arch) do
    "_build/liberlang.xcframework"
  end
end
