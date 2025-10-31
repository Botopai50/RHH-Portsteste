const fs = require('fs').promises;
const path = require('path');

const screenshotExtensions = ['.png', '.jpg', '.jpeg'];

/**
 * Recursively find all ports with a port.json and a screenshot.
 * Also computes latest modified timestamp for each port.
 */
async function findPorts(baseDir) {
	const ports = [];

	async function walk(currentDir) {
		const entries = await fs.readdir(currentDir, { withFileTypes: true });

		// Check subdirectories for port.json and screenshot
		for (const entry of entries) {
			if (!entry.isDirectory()) continue;

			const subDir = path.join(currentDir, entry.name);
			const subEntries = await fs.readdir(subDir, { withFileTypes: true });

			const portJson = subEntries.find(e => e.isFile() && e.name.toLowerCase() === 'port.json');
			const screenshot = subEntries.find(
				e => e.isFile() &&
					 e.name.toLowerCase().startsWith('screenshot') &&
					 screenshotExtensions.includes(path.extname(e.name).toLowerCase())
			);

			if (portJson && screenshot) {
				let latestMtime = 0;

				// Recursively compute latest modified timestamp in the subfolder
				async function getLatest(dir) {
					const allEntries = await fs.readdir(dir, { withFileTypes: true });
					for (const e of allEntries) {
						const fullPath = path.join(dir, e.name);
						if (e.isFile()) {
							const stat = await fs.stat(fullPath);
							if (stat.mtimeMs > latestMtime) latestMtime = stat.mtimeMs;
						} else if (e.isDirectory()) {
							await getLatest(fullPath);
						}
					}
				}
				await getLatest(subDir);

				try {
					const portRaw = await fs.readFile(path.join(subDir, 'port.json'), 'utf-8');
					const data = JSON.parse(portRaw);

					const relDir = path.relative(baseDir, subDir).split(path.sep).join('/');
					const downloadDir = path.relative(baseDir, path.dirname(subDir)).split(path.sep).join('/');

					ports.push({
						title: data.attr?.title || entry.name,
						description: data.attr?.desc || '',
						download_url: `https://github.com/JeodC/RHH-Ports/tree/main/ports/released/${downloadDir}`,
						screenshot_url: `https://raw.githubusercontent.com/JeodC/RHH-Ports/main/ports/released/${relDir}/${screenshot.name}`,
						porter: data.attr?.porter || [],
						genres: data.attr?.genres || [],
						availability: data.attr?.availability || 'unknown',
						store: data.attr?.store || [],
						instructions: data.attr?.inst || '',
						runtime: data.attr?.runtime || [],
						exp: data.attr?.exp || false,
						rtr: data.attr?.rtr || false,
						arch: data.attr?.arch || [],
						min_glibc: data.attr?.min_glibc || '',
						last_modified: new Date(latestMtime || Date.now()).toISOString(),
						requirements: (data.attr?.reqs || []).join(', '),
					});
				} catch (err) {
					console.warn(`Failed to process ${subDir}: ${err.message}`);
				}
			}

			// Recurse into subdirectory
			await walk(subDir);
		}
	}

	await walk(baseDir);
	return ports;
}

/**
 * Main function
 */
async function main() {
	const baseDir = path.resolve('./ports/released');
	const outputFile = path.resolve('./docs/ports.json');

	const ports = await findPorts(baseDir);

	// Sort alphabetically
	ports.sort((a, b) => a.title.toLowerCase().localeCompare(b.title.toLowerCase()));

	await fs.writeFile(outputFile, JSON.stringify(ports, null, 2), 'utf-8');
	console.log(`Generated ports.json with ${ports.length} ports.`);
}

main().catch(err => {
	console.error(err);
	process.exit(1);
});
