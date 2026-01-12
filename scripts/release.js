#!/usr/bin/env node

/**
 * Interactive release script for WhisperX
 *
 * Usage: node scripts/release.js
 *
 * Guides you through creating stable, beta, or alpha releases.
 */

const readline = require('readline');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// ANSI colors for terminal output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m',
  bold: '\x1b[1m',
};

const log = {
  error: (msg) => console.log(`${colors.red}${colors.bold}Error:${colors.reset} ${msg}`),
  warn: (msg) => console.log(`${colors.yellow}${colors.bold}Warning:${colors.reset} ${msg}`),
  success: (msg) => console.log(`${colors.green}${colors.bold}Success:${colors.reset} ${msg}`),
  info: (msg) => console.log(`${colors.cyan}${msg}${colors.reset}`),
  step: (msg) => console.log(`\n${colors.blue}${colors.bold}==>${colors.reset} ${colors.bold}${msg}${colors.reset}`),
  dim: (msg) => console.log(`${colors.dim}${msg}${colors.reset}`),
};

// ============================================================================
// Git Utilities
// ============================================================================

function exec(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf-8' }).trim();
  } catch (error) {
    return null;
  }
}

function getCurrentBranch() {
  return exec('git branch --show-current');
}

function hasUncommittedChanges() {
  const status = exec('git status --porcelain');
  return status && status.length > 0;
}

function getLatestStableTag() {
  // Get all tags, filter for stable versions (no -alpha, -beta, -dev), sort by version
  const tags = exec('git tag -l "v*"');
  if (!tags) return null;

  const stableTags = tags
    .split('\n')
    .filter(tag => !tag.includes('-alpha') && !tag.includes('-beta') && !tag.includes('-dev'))
    .sort((a, b) => {
      const parseVersion = (v) => {
        const match = v.match(/v?(\d+)\.(\d+)\.(\d+)/);
        if (!match) return [0, 0, 0];
        return [parseInt(match[1]), parseInt(match[2]), parseInt(match[3])];
      };
      const [aMajor, aMinor, aPatch] = parseVersion(a);
      const [bMajor, bMinor, bPatch] = parseVersion(b);
      if (aMajor !== bMajor) return bMajor - aMajor;
      if (aMinor !== bMinor) return bMinor - aMinor;
      return bPatch - aPatch;
    });

  return stableTags[0] || null;
}

function getCommitCountSinceTag(tag) {
  const cmd = tag ? `git rev-list ${tag}..HEAD --count` : `git rev-list HEAD --count`;
  const count = exec(cmd);
  return count ? parseInt(count) : 0;
}

function getLatestPrereleaseCount(type) {
  // Get the latest alpha/beta tag and extract its count (e.g., v0.1.0-alpha.5 -> 5)
  const tags = exec('git tag -l "v*"');
  if (!tags) return null;

  const pattern = new RegExp(`-${type}\\.(\\d+)$`);
  const matchingTags = tags
    .split('\n')
    .filter(tag => pattern.test(tag))
    .map(tag => {
      const match = tag.match(pattern);
      return match ? parseInt(match[1]) : 0;
    })
    .sort((a, b) => b - a);

  return matchingTags.length > 0 ? matchingTags[0] : null;
}

function getLatestTagForType(type) {
  // Get the latest tag for a specific release type (alpha, beta, or stable)
  const tags = exec('git tag -l "v*"');
  if (!tags) return null;

  let pattern;
  if (type === 'stable') {
    // Stable tags have no suffix (e.g., v0.1.0)
    pattern = /^v(\d+)\.(\d+)\.(\d+)$/;
  } else {
    // Alpha/beta tags: v0.1.0-alpha.N or v0.1.0-beta.N
    pattern = new RegExp(`^v(\\d+)\\.(\\d+)\\.(\\d+)-${type}\\.(\\d+)$`);
  }

  const matchingTags = tags
    .split('\n')
    .filter(tag => pattern.test(tag))
    .sort((a, b) => {
      // Sort by version components, then by prerelease number
      const parseTag = (t) => {
        const match = t.match(/^v(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta)\.(\d+))?$/);
        if (!match) return [0, 0, 0, 0];
        return [
          parseInt(match[1]),
          parseInt(match[2]),
          parseInt(match[3]),
          match[5] ? parseInt(match[5]) : 0
        ];
      };
      const [aMaj, aMin, aPat, aPre] = parseTag(a);
      const [bMaj, bMin, bPat, bPre] = parseTag(b);
      if (aMaj !== bMaj) return bMaj - aMaj;
      if (aMin !== bMin) return bMin - aMin;
      if (aPat !== bPat) return bPat - aPat;
      return bPre - aPre;
    });

  return matchingTags[0] || null;
}

function getHighestBaseVersion() {
  // Get the highest base version from all tags (stable and pre-release)
  // e.g., v0.1.0, v0.1.0-alpha.1, v0.2.0-beta.3 -> returns "0.2.0"
  const tags = exec('git tag -l "v*"');
  if (!tags) return null;

  const versions = tags
    .split('\n')
    .map(tag => {
      const match = tag.match(/^v?(\d+)\.(\d+)\.(\d+)/);
      if (!match) return null;
      return {
        major: parseInt(match[1]),
        minor: parseInt(match[2]),
        patch: parseInt(match[3]),
        str: `${match[1]}.${match[2]}.${match[3]}`,
      };
    })
    .filter(v => v !== null)
    .sort((a, b) => {
      if (a.major !== b.major) return b.major - a.major;
      if (a.minor !== b.minor) return b.minor - a.minor;
      return b.patch - a.patch;
    });

  return versions.length > 0 ? versions[0].str : null;
}

function tagExists(tag) {
  const result = exec(`git tag -l "${tag}"`);
  return result === tag;
}

function getCommitsSinceTag(tag) {
  const format = '%H|%s|%b|END_COMMIT';
  let cmd;
  if (tag) {
    cmd = `git log ${tag}..HEAD --format="${format}"`;
  } else {
    cmd = `git log --format="${format}"`;
  }

  const output = exec(cmd);
  if (!output) return [];

  const commits = [];
  const rawCommits = output.split('|END_COMMIT').filter(c => c.trim());

  for (const raw of rawCommits) {
    const parts = raw.trim().split('|');
    if (parts.length >= 2) {
      const hash = parts[0];
      const subject = parts[1];
      const body = parts.slice(2).join('|').trim();
      commits.push({ hash, subject, body });
    }
  }

  return commits;
}

// ============================================================================
// Version Calculation
// ============================================================================

function calculateVersion(type, latestStableTag) {
  const commitCount = getCommitCountSinceTag(latestStableTag);

  if (commitCount === 0) {
    return null; // No new commits
  }

  // Use highest base version from all tags (stable or pre-release)
  // Falls back to stable tag, then to 0.1.0 if nothing exists
  let baseVersion;
  if (latestStableTag) {
    baseVersion = latestStableTag.replace(/^v/, '');
  } else {
    baseVersion = getHighestBaseVersion() || '0.1.0';
  }

  return `${baseVersion}-${type}.${commitCount}`;
}

// ============================================================================
// Changelog Generation
// ============================================================================

function categorizeCommits(commits) {
  const categories = {
    feat: { title: 'Added', commits: [] },
    fix: { title: 'Fixed', commits: [] },
    docs: { title: 'Documentation', commits: [] },
    refactor: { title: 'Changed', commits: [] },
    perf: { title: 'Performance', commits: [] },
    test: { title: 'Testing', commits: [] },
    chore: { title: 'Maintenance', commits: [] },
    other: { title: 'Other', commits: [] },
  };

  for (const commit of commits) {
    const match = commit.subject.match(/^(\w+)(?:\(.+\))?:\s*(.+)/);
    if (match) {
      const type = match[1].toLowerCase();
      const message = match[2];
      const category = categories[type] || categories.other;
      category.commits.push({ ...commit, message });
    } else {
      categories.other.commits.push({ ...commit, message: commit.subject });
    }
  }

  return categories;
}

function generateChangelogContent(version, commits) {
  const categories = categorizeCommits(commits);
  const date = new Date().toISOString().split('T')[0];

  let content = `## [${version}] - ${date}\n\n`;

  for (const [key, category] of Object.entries(categories)) {
    if (category.commits.length > 0) {
      content += `### ${category.title}\n`;
      for (const commit of category.commits) {
        content += `- ${commit.message}\n`;
        if (commit.body) {
          const bodyLines = commit.body.split('\n').filter(l => l.trim());
          for (const line of bodyLines) {
            if (!line.startsWith('Co-Authored-By') && !line.startsWith('Signed-off-by')) {
              content += `  ${line}\n`;
            }
          }
        }
      }
      content += '\n';
    }
  }

  return content;
}

function updateChangelogFile(newContent) {
  const changelogPath = path.join(process.cwd(), 'CHANGELOG.md');

  let existingContent = '';
  if (fs.existsSync(changelogPath)) {
    existingContent = fs.readFileSync(changelogPath, 'utf-8');
  } else {
    existingContent = '# Changelog\n\nAll notable changes to this project will be documented in this file.\n\n';
  }

  // Find the position after the header to insert new content
  const headerEndMatch = existingContent.match(/^# Changelog\n+(?:.*\n)*?\n(?=## |$)/m);
  if (headerEndMatch) {
    const insertPos = headerEndMatch[0].length;
    const before = existingContent.slice(0, insertPos);
    const after = existingContent.slice(insertPos);
    existingContent = before + newContent + after;
  } else {
    existingContent += '\n' + newContent;
  }

  fs.writeFileSync(changelogPath, existingContent);
}

// ============================================================================
// Git Operations
// ============================================================================

function commitChangelog(version) {
  exec('git add CHANGELOG.md');
  exec(`git commit -m "docs: add changelog for v${version}"`);
}

function createTag(version) {
  exec(`git tag v${version}`);
}

function pushTagAndCommit() {
  exec('git push origin main');
  exec('git push origin --tags');
}

// ============================================================================
// Interactive Prompts
// ============================================================================

function createInterface() {
  return readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
}

async function ask(rl, question) {
  return new Promise((resolve) => {
    rl.question(`${question} ${colors.dim}(y/n)${colors.reset} `, (answer) => {
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

async function select(rl, question, options) {
  console.log(`\n${question}`);
  options.forEach((opt, i) => {
    console.log(`  ${colors.cyan}${i + 1}${colors.reset}) ${opt}`);
  });

  return new Promise((resolve) => {
    rl.question(`\nSelect ${colors.dim}(1-${options.length})${colors.reset}: `, (answer) => {
      const index = parseInt(answer) - 1;
      if (index >= 0 && index < options.length) {
        resolve(options[index]);
      } else {
        resolve(null);
      }
    });
  });
}

async function input(rl, question) {
  return new Promise((resolve) => {
    rl.question(`${question}: `, (answer) => {
      resolve(answer.trim());
    });
  });
}

// ============================================================================
// Main Flow
// ============================================================================

async function main() {
  console.log(`\n${colors.bold}${colors.cyan}WhisperX Release Script${colors.reset}\n`);

  const rl = createInterface();

  try {
    // Step 1: Check branch
    log.step('Checking git branch');
    const branch = getCurrentBranch();
    if (branch !== 'main') {
      log.error(`You must be on the 'main' branch to create a release.`);
      log.info(`Current branch: ${branch}`);
      log.info(`Run: git checkout main`);
      process.exit(1);
    }
    log.success(`On main branch`);

    // Step 2: Check for uncommitted changes
    log.step('Checking for uncommitted changes');
    if (hasUncommittedChanges()) {
      log.warn('You have uncommitted changes.');
      const proceed = await ask(rl, 'Continue anyway?');
      if (!proceed) {
        log.info('Aborted. Commit or stash your changes first.');
        process.exit(0);
      }
    } else {
      log.success('Working directory is clean');
    }

    // Step 3: Select release type
    log.step('Select release type');
    const releaseType = await select(rl, 'What type of release?', ['alpha', 'beta', 'stable']);
    if (!releaseType) {
      log.error('Invalid selection');
      process.exit(1);
    }

    // Step 4: Calculate or get version
    log.step('Determining version');
    const latestStable = getLatestStableTag();
    const highestBase = getHighestBaseVersion();
    log.info(`Latest stable tag: ${latestStable || 'none'}`);
    if (highestBase && !latestStable) {
      log.info(`Highest base version (from pre-release): ${highestBase}`);
    }

    let version;
    if (releaseType === 'stable') {
      version = await input(rl, 'Enter version number (e.g., 0.2.0)');
      if (!version || !version.match(/^\d+\.\d+\.\d+$/)) {
        log.error('Invalid version format. Use X.Y.Z (e.g., 0.2.0)');
        process.exit(1);
      }
      // Validate stable version is >= highest existing base version
      if (highestBase) {
        const parseVer = (v) => {
          const m = v.match(/(\d+)\.(\d+)\.(\d+)/);
          return m ? [parseInt(m[1]), parseInt(m[2]), parseInt(m[3])] : [0, 0, 0];
        };
        const [newMaj, newMin, newPatch] = parseVer(version);
        const [oldMaj, oldMin, oldPatch] = parseVer(highestBase);
        const isValid = newMaj > oldMaj ||
          (newMaj === oldMaj && newMin > oldMin) ||
          (newMaj === oldMaj && newMin === oldMin && newPatch >= oldPatch);
        if (!isValid) {
          log.error(`Stable version must be >= ${highestBase} (highest existing version).`);
          process.exit(1);
        }
      }
    } else {
      version = calculateVersion(releaseType, latestStable);
      if (!version) {
        log.error('No new commits since last stable release. Nothing to release.');
        process.exit(1);
      }

      // Validate beta has >= commits than latest alpha
      if (releaseType === 'beta') {
        const latestAlphaCount = getLatestPrereleaseCount('alpha');
        const currentCount = getCommitCountSinceTag(latestStable);
        if (latestAlphaCount !== null && currentCount < latestAlphaCount) {
          log.error(`Beta release requires at least ${latestAlphaCount} commits (latest alpha count).`);
          log.info(`Current commit count: ${currentCount}`);
          process.exit(1);
        }
      }
    }

    log.info(`Calculated version: ${colors.bold}v${version}${colors.reset}`);

    // Step 5: Check if tag exists
    if (tagExists(`v${version}`)) {
      log.error(`Tag v${version} already exists. This release has already been created.`);
      process.exit(1);
    }

    // Step 6: Generate changelog
    log.step('Generating changelog');
    const latestTagForType = getLatestTagForType(releaseType);
    log.info(`Latest ${releaseType} tag: ${latestTagForType || 'none'}`);
    const commits = getCommitsSinceTag(latestTagForType);
    if (commits.length === 0) {
      log.warn('No commits found since last release.');
    } else {
      log.info(`Found ${commits.length} commits since ${latestTagForType || 'beginning'}`);
    }

    const changelogContent = generateChangelogContent(version, commits);
    console.log(`\n${colors.dim}--- Changelog Preview ---${colors.reset}`);
    console.log(changelogContent);
    console.log(`${colors.dim}--- End Preview ---${colors.reset}\n`);

    // Step 7: Update changelog
    const updateChangelog = await ask(rl, 'Update CHANGELOG.md with this content?');
    if (updateChangelog) {
      updateChangelogFile(changelogContent);
      log.success('CHANGELOG.md updated');
    }

    // Step 8: Commit changelog
    if (updateChangelog) {
      const commitCl = await ask(rl, 'Commit the changelog update?');
      if (commitCl) {
        commitChangelog(version);
        log.success('Changelog committed');
      }
    }

    // Step 9: Create tag
    const createT = await ask(rl, `Create tag v${version}?`);
    if (createT) {
      createTag(version);
      log.success(`Tag v${version} created`);
    }

    // Step 10: Push
    if (createT) {
      const push = await ask(rl, 'Push commit and tag to origin?');
      if (push) {
        log.info('Pushing to origin...');
        pushTagAndCommit();
        log.success('Pushed to origin');
        console.log(`\n${colors.green}${colors.bold}Release v${version} initiated!${colors.reset}`);
        log.info(`Monitor CI: https://github.com/sadiksaifi/WhisperX/actions`);
        log.info(`View release: https://github.com/sadiksaifi/WhisperX/releases`);
      }
    }

    console.log('');
  } finally {
    rl.close();
  }
}

// Run
main().catch((err) => {
  log.error(err.message);
  process.exit(1);
});
