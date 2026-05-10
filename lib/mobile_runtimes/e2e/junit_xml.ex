defmodule MobileRuntimes.E2E.JUnitXML do
  @moduledoc """
  Generates JUnit XML reports from E2E test results.

  The generated XML conforms to the JUnit XML schema and is compatible with
  GitHub Actions test result visualization and other CI tools.
  """

  alias MobileRuntimes.E2E.{Architecture, TestCase, TestReport, TestSuite}

  @doc """
  Generates JUnit XML string from a test report.
  """
  @spec generate(TestReport.t()) :: String.t()
  def generate(%TestReport{} = report) do
    suites_xml = Enum.map(report.suites, &testsuite_xml/1) |> Enum.join("\n")
    time_sec = Float.round(report.total_time_ms / 1000, 3)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <testsuites name="E2E Runtime Tests" tests="#{report.total_tests}" failures="#{report.total_failures}" errors="#{report.total_errors}" time="#{time_sec}">
    #{suites_xml}
    </testsuites>
    """
    |> String.trim()
  end

  @doc """
  Writes JUnit XML report to a file.
  """
  @spec write_to_file(TestReport.t(), Path.t()) :: :ok | {:error, term()}
  def write_to_file(%TestReport{} = report, path) do
    xml = generate(report)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, xml) do
      :ok
    end
  end

  @doc """
  Generates JUnit XML from a list of test suites (convenience function).
  """
  @spec from_suites([TestSuite.t()]) :: String.t()
  def from_suites(suites) when is_list(suites) do
    report = TestReport.new(suites)
    generate(report)
  end

  defp testsuite_xml(%TestSuite{} = suite) do
    arch_name = Architecture.to_string(suite.architecture)
    counts = TestSuite.count_by_status(suite)
    time_sec = Float.round(suite.total_time_ms / 1000, 3)

    tests_xml = Enum.map(suite.tests, &testcase_xml/1) |> Enum.join("\n")

    """
      <testsuite name="#{arch_name}" tests="#{length(suite.tests)}" failures="#{counts.failed}" errors="#{counts.error}" skipped="#{counts.skipped}" time="#{time_sec}">
    #{tests_xml}
      </testsuite>
    """
    |> String.trim_trailing()
  end

  defp testcase_xml(%TestCase{} = test) do
    time_sec = Float.round(test.time_ms / 1000, 3)
    classname = category_to_classname(test.category)

    base =
      "    <testcase classname=\"#{classname}\" name=\"#{escape_xml(test.name)}\" time=\"#{time_sec}\""

    case test.status do
      :passed ->
        "#{base}/>"

      :failed ->
        failure_xml = failure_element(test.error_message, test.stdout)
        "#{base}>\n#{failure_xml}\n    </testcase>"

      :error ->
        error_xml = error_element(test.error_message)
        "#{base}>\n#{error_xml}\n    </testcase>"

      :skipped ->
        "#{base}>\n      <skipped/>\n    </testcase>"
    end
  end

  defp category_to_classname(:boot), do: "BeamBoot"
  defp category_to_classname(:execution), do: "ElixirExecution"
  defp category_to_classname(:nif), do: "NifIntegration"

  defp failure_element(message, stdout) do
    content =
      [message, stdout]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n\n")
      |> escape_xml()

    "      <failure message=\"#{escape_attr(message || "Test failed")}\"><![CDATA[#{content}]]></failure>"
  end

  defp error_element(message) do
    "      <error message=\"#{escape_attr(message || "Test error")}\"><![CDATA[#{escape_xml(message || "")}]]></error>"
  end

  defp escape_xml(nil), do: ""

  defp escape_xml(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_attr(nil), do: ""

  defp escape_attr(str) when is_binary(str) do
    str
    |> escape_xml()
    |> String.replace("\"", "&quot;")
    |> String.replace("\n", "&#10;")
  end
end
