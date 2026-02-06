// HTMLReporter.swift
// GherkinTesting
//
// Copyright © 2026 Atelier Socle. MIT License.

import Foundation

/// Generates a standalone HTML report with inline CSS and JavaScript.
///
/// The report is a single self-contained HTML file with:
/// - Summary dashboard with pass/fail/skip counts and percentages
/// - Feature list with collapsible scenario details
/// - Color-coded steps by status (green/red/yellow/grey/orange)
/// - Tag badges and duration display on each element
/// - Interactive filters by status and tag
/// - Responsive layout with dark mode support
///
/// ```swift
/// let reporter = HTMLReporter()
/// // ... run tests with this reporter ...
/// let data = try await reporter.generateReport()
/// try data.write(to: URL(fileURLWithPath: "report.html"))
/// ```
public actor HTMLReporter: GherkinReporter {
    private var runResult: TestRunResult?

    /// Creates a new HTML reporter.
    public init() {}

    public func featureStarted(_ feature: FeatureResult) {}

    public func scenarioStarted(_ scenario: ScenarioResult) {}

    public func stepFinished(_ step: StepResult) {}

    public func scenarioFinished(_ scenario: ScenarioResult) {}

    public func featureFinished(_ feature: FeatureResult) {}

    public func testRunFinished(_ result: TestRunResult) {
        runResult = result
    }

    public func generateReport() throws -> Data {
        let html = buildHTML(runResult)
        guard let data = html.data(using: .utf8) else {
            throw ReporterError.encodingFailed
        }
        return data
    }
}

// MARK: - HTML Building

extension HTMLReporter {
    private func buildHTML(_ result: TestRunResult?) -> String {
        let result = result ?? TestRunResult(featureResults: [], duration: .zero)
        var html = ""
        html += "<!DOCTYPE html>\n"
        html += "<html lang=\"en\">\n"
        html += "<head>\n"
        html += "<meta charset=\"UTF-8\">\n"
        html += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
        html += "<title>Gherkin Test Report</title>\n"
        html += "<style>\n"
        html += inlineCSS()
        html += "</style>\n"
        html += "</head>\n"
        html += "<body>\n"
        html += buildSummary(result)
        html += buildFilters(result)
        html += buildFeatures(result)
        html += "<script>\n"
        html += inlineJS()
        html += "</script>\n"
        html += "</body>\n"
        html += "</html>\n"
        return html
    }

    private func buildSummary(_ result: TestRunResult) -> String {
        let total = result.totalCount
        let passed = result.passedCount
        let failed = result.failedCount
        let skipped = result.skippedCount
        let pending = result.pendingCount
        let undefined = result.undefinedCount
        let duration = formatDuration(result.duration)
        let passRate = total > 0 ? Int(Double(passed) / Double(total) * 100) : 0

        var html = "<div class=\"summary\">\n"
        html += "<h1>Gherkin Test Report</h1>\n"
        html += "<div class=\"summary-grid\">\n"
        html += summaryCard("Total", "\(total)", "total")
        html += summaryCard("Passed", "\(passed)", "passed")
        html += summaryCard("Failed", "\(failed)", "failed")
        html += summaryCard("Skipped", "\(skipped)", "skipped")
        html += summaryCard("Pending", "\(pending)", "pending")
        html += summaryCard("Undefined", "\(undefined)", "undefined")
        html += summaryCard("Pass Rate", "\(passRate)%", passRate == 100 ? "passed" : "total")
        html += summaryCard("Duration", duration, "total")
        html += "</div>\n"
        html += "</div>\n"
        return html
    }

    private func summaryCard(_ label: String, _ value: String, _ cssClass: String) -> String {
        var html = "<div class=\"summary-card \(cssClass)\">\n"
        html += "<div class=\"card-value\">\(value)</div>\n"
        html += "<div class=\"card-label\">\(label)</div>\n"
        html += "</div>\n"
        return html
    }

    private func buildFilters(_ result: TestRunResult) -> String {
        let allTags = collectAllTags(result)

        var html = "<div class=\"filters\">\n"
        html += "<div class=\"status-filters\">\n"
        html += "<button class=\"filter-btn active\" data-status=\"all\">All</button>\n"
        html += "<button class=\"filter-btn\" data-status=\"passed\">Passed</button>\n"
        html += "<button class=\"filter-btn\" data-status=\"failed\">Failed</button>\n"
        html += "<button class=\"filter-btn\" data-status=\"skipped\">Skipped</button>\n"
        html += "<button class=\"filter-btn\" data-status=\"pending\">Pending</button>\n"
        html += "<button class=\"filter-btn\" data-status=\"undefined\">Undefined</button>\n"
        html += "</div>\n"

        if !allTags.isEmpty {
            html += "<select class=\"tag-filter\" id=\"tagFilter\">\n"
            html += "<option value=\"all\">All Tags</option>\n"
            for tag in allTags.sorted() {
                html += "<option value=\"\(escapeHTML(tag))\">\(escapeHTML(tag))</option>\n"
            }
            html += "</select>\n"
        }

        html += "</div>\n"
        return html
    }

    private func buildFeatures(_ result: TestRunResult) -> String {
        var html = "<div class=\"features\">\n"
        for feature in result.featureResults {
            html += buildFeature(feature)
        }
        html += "</div>\n"
        return html
    }

    private func buildFeature(_ feature: FeatureResult) -> String {
        let statusClass = statusToCSSClass(feature.status)
        let duration = formatDuration(feature.duration)

        var html = "<div class=\"feature\" data-status=\"\(statusClass)\">\n"
        html += "<div class=\"feature-header\" onclick=\"toggleFeature(this)\">\n"
        html += "<span class=\"toggle-icon\">&#9654;</span>\n"
        html += "<span class=\"feature-name\">Feature: \(escapeHTML(feature.name))</span>\n"
        html += buildTagBadges(feature.tags)
        html += "<span class=\"duration\">\(duration)</span>\n"
        html += "<span class=\"status-badge \(statusClass)\">\(statusClass)</span>\n"
        html += "</div>\n"
        html += "<div class=\"feature-body\" style=\"display:none;\">\n"
        for scenario in feature.scenarioResults {
            html += buildScenario(scenario)
        }
        html += "</div>\n"
        html += "</div>\n"
        return html
    }

    private func buildScenario(_ scenario: ScenarioResult) -> String {
        let statusClass = statusToCSSClass(scenario.status)
        let duration = formatDuration(scenario.duration)
        let tagsData = scenario.tags.joined(separator: ",")

        var html = "<div class=\"scenario\" data-status=\"\(statusClass)\""
        html += " data-tags=\"\(escapeHTML(tagsData))\">\n"
        html += "<div class=\"scenario-header\" onclick=\"toggleScenario(this)\">\n"
        html += "<span class=\"toggle-icon\">&#9654;</span>\n"
        html += "<span class=\"scenario-name\">Scenario: \(escapeHTML(scenario.name))</span>\n"
        html += buildTagBadges(scenario.tags)
        html += "<span class=\"duration\">\(duration)</span>\n"
        html += "<span class=\"status-badge \(statusClass)\">\(statusClass)</span>\n"
        html += "</div>\n"
        html += "<div class=\"scenario-body\" style=\"display:none;\">\n"
        for stepResult in scenario.stepResults {
            html += buildStepRow(stepResult)
        }
        html += "</div>\n"
        html += "</div>\n"
        return html
    }

    private func buildStepRow(_ step: StepResult) -> String {
        let statusClass = statusToCSSClass(step.status)
        let duration = formatDuration(step.duration)

        var html = "<div class=\"step \(statusClass)\">\n"
        html += "<span class=\"step-text\">\(escapeHTML(step.step.text))</span>\n"
        html += "<span class=\"duration\">\(duration)</span>\n"
        html += "<span class=\"status-badge \(statusClass)\">\(statusClass)</span>\n"
        if case .failed(let failure) = step.status {
            html += "<div class=\"error-message\">\(escapeHTML(failure.message))</div>\n"
        }
        html += "</div>\n"
        return html
    }

    private func buildTagBadges(_ tags: [String]) -> String {
        guard !tags.isEmpty else { return "" }
        var html = "<span class=\"tags\">"
        for tag in tags {
            html += "<span class=\"tag-badge\">\(escapeHTML(tag))</span>"
        }
        html += "</span>"
        return html
    }

    private func collectAllTags(_ result: TestRunResult) -> Set<String> {
        var tags = Set<String>()
        for feature in result.featureResults {
            tags.formUnion(feature.tags)
            for scenario in feature.scenarioResults {
                tags.formUnion(scenario.tags)
            }
        }
        return tags
    }

    private func statusToCSSClass(_ status: StepStatus) -> String {
        switch status {
        case .passed: return "passed"
        case .failed: return "failed"
        case .skipped: return "skipped"
        case .pending: return "pending"
        case .undefined: return "undefined"
        case .ambiguous: return "ambiguous"
        }
    }

    private func formatDuration(_ duration: Duration) -> String {
        let components = duration.components
        let totalSeconds = Double(components.seconds)
            + Double(components.attoseconds) / 1e18
        if totalSeconds < 1 {
            return String(format: "%.0fms", totalSeconds * 1000)
        }
        return String(format: "%.3fs", totalSeconds)
    }

    private func escapeHTML(_ string: String) -> String {
        var result = string
        result = result.replacing("&", with: "&amp;")
        result = result.replacing("<", with: "&lt;")
        result = result.replacing(">", with: "&gt;")
        result = result.replacing("\"", with: "&quot;")
        result = result.replacing("'", with: "&#39;")
        return result
    }
}

// MARK: - Inline CSS

extension HTMLReporter {
    private func inlineCSS() -> String {
        """
        :root {
          --bg: #ffffff; --fg: #1a1a2e; --card-bg: #f8f9fa;
          --border: #dee2e6; --passed: #28a745; --failed: #dc3545;
          --skipped: #6c757d; --pending: #ffc107; --undefined: #fd7e14;
          --ambiguous: #e83e8c;
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #1a1a2e; --fg: #e0e0e0; --card-bg: #16213e;
            --border: #333; --passed: #2ecc71; --failed: #e74c3c;
            --skipped: #95a5a6; --pending: #f39c12; --undefined: #e67e22;
            --ambiguous: #e84393;
          }
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
               background: var(--bg); color: var(--fg); padding: 20px; max-width: 1200px; margin: 0 auto; }
        h1 { margin-bottom: 16px; }
        .summary { margin-bottom: 24px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 12px; }
        .summary-card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 8px;
                        padding: 16px; text-align: center; }
        .summary-card.passed { border-left: 4px solid var(--passed); }
        .summary-card.failed { border-left: 4px solid var(--failed); }
        .summary-card.skipped { border-left: 4px solid var(--skipped); }
        .summary-card.pending { border-left: 4px solid var(--pending); }
        .summary-card.undefined { border-left: 4px solid var(--undefined); }
        .summary-card.total { border-left: 4px solid var(--border); }
        .card-value { font-size: 24px; font-weight: bold; }
        .card-label { font-size: 12px; color: var(--skipped); margin-top: 4px; }
        .filters { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 20px; align-items: center; }
        .status-filters { display: flex; gap: 4px; flex-wrap: wrap; }
        .filter-btn { padding: 6px 14px; border: 1px solid var(--border); border-radius: 4px;
                      background: var(--card-bg); color: var(--fg); cursor: pointer; font-size: 13px; }
        .filter-btn.active { background: var(--fg); color: var(--bg); }
        .tag-filter { padding: 6px 10px; border: 1px solid var(--border); border-radius: 4px;
                      background: var(--card-bg); color: var(--fg); font-size: 13px; }
        .feature { border: 1px solid var(--border); border-radius: 8px; margin-bottom: 12px; overflow: hidden; }
        .feature-header, .scenario-header { padding: 12px 16px; cursor: pointer; display: flex;
                                             align-items: center; gap: 8px; background: var(--card-bg); }
        .feature-header:hover, .scenario-header:hover { opacity: 0.85; }
        .toggle-icon { font-size: 10px; transition: transform 0.2s; display: inline-block; }
        .toggle-icon.open { transform: rotate(90deg); }
        .feature-name, .scenario-name { flex: 1; font-weight: 600; }
        .scenario { border-top: 1px solid var(--border); }
        .step { padding: 8px 16px 8px 40px; display: flex; align-items: center; gap: 8px;
                border-top: 1px solid var(--border); flex-wrap: wrap; }
        .step.passed { border-left: 3px solid var(--passed); }
        .step.failed { border-left: 3px solid var(--failed); }
        .step.skipped { border-left: 3px solid var(--skipped); }
        .step.pending { border-left: 3px solid var(--pending); }
        .step.undefined { border-left: 3px solid var(--undefined); }
        .step.ambiguous { border-left: 3px solid var(--ambiguous); }
        .step-text { flex: 1; }
        .duration { font-size: 12px; color: var(--skipped); white-space: nowrap; }
        .status-badge { font-size: 11px; padding: 2px 8px; border-radius: 10px; font-weight: 600;
                        text-transform: uppercase; white-space: nowrap; }
        .status-badge.passed { background: var(--passed); color: #fff; }
        .status-badge.failed { background: var(--failed); color: #fff; }
        .status-badge.skipped { background: var(--skipped); color: #fff; }
        .status-badge.pending { background: var(--pending); color: #000; }
        .status-badge.undefined { background: var(--undefined); color: #fff; }
        .status-badge.ambiguous { background: var(--ambiguous); color: #fff; }
        .tag-badge { font-size: 11px; padding: 1px 6px; border-radius: 3px;
                     background: var(--border); margin-right: 4px; }
        .tags { display: inline-flex; gap: 2px; }
        .error-message { width: 100%; padding: 8px 12px; margin-top: 4px; background: rgba(220,53,69,0.1);
                         border-radius: 4px; font-family: monospace; font-size: 13px; white-space: pre-wrap;
                         color: var(--failed); }
        @media (max-width: 600px) {
          .summary-grid { grid-template-columns: repeat(2, 1fr); }
          body { padding: 10px; }
        }
        """
    }
}

// MARK: - Inline JavaScript

extension HTMLReporter {
    private func inlineJS() -> String {
        """
        function toggleFeature(header) {
          var body = header.nextElementSibling;
          var icon = header.querySelector('.toggle-icon');
          if (body.style.display === 'none') {
            body.style.display = 'block';
            icon.classList.add('open');
          } else {
            body.style.display = 'none';
            icon.classList.remove('open');
          }
        }
        function toggleScenario(header) {
          var body = header.nextElementSibling;
          var icon = header.querySelector('.toggle-icon');
          if (body.style.display === 'none') {
            body.style.display = 'block';
            icon.classList.add('open');
          } else {
            body.style.display = 'none';
            icon.classList.remove('open');
          }
        }
        document.querySelectorAll('.filter-btn').forEach(function(btn) {
          btn.addEventListener('click', function() {
            document.querySelectorAll('.filter-btn').forEach(function(b) { b.classList.remove('active'); });
            btn.classList.add('active');
            var status = btn.getAttribute('data-status');
            applyFilters();
          });
        });
        var tagSelect = document.getElementById('tagFilter');
        if (tagSelect) {
          tagSelect.addEventListener('change', function() { applyFilters(); });
        }
        function applyFilters() {
          var activeBtn = document.querySelector('.filter-btn.active');
          var status = activeBtn ? activeBtn.getAttribute('data-status') : 'all';
          var tag = tagSelect ? tagSelect.value : 'all';
          document.querySelectorAll('.scenario').forEach(function(el) {
            var elStatus = el.getAttribute('data-status');
            var elTags = el.getAttribute('data-tags') || '';
            var statusMatch = (status === 'all' || elStatus === status);
            var tagMatch = (tag === 'all' || elTags.indexOf(tag) !== -1);
            el.style.display = (statusMatch && tagMatch) ? '' : 'none';
          });
        }
        """
    }
}
