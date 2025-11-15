// TODO: Move this into a system submodule when we have a
// cleaned up system module

import type Umbreld from '../../index.js'

export default class Dbus {
	#umbreld: Umbreld
	logger: Umbreld['logger']
	#removeDiskEventListeners?: () => void

	constructor(umbreld: Umbreld) {
		this.#umbreld = umbreld
		const {name} = this.constructor
		this.logger = umbreld.logger.createChildLogger(name.toLocaleLowerCase())
	}

	async start() {
		this.logger.log('Starting dbus')
		// DBus functionality disabled in Docker container
		return
	}

	async stop() {
		this.logger.log('Stopping dbus')
		this.#removeDiskEventListeners?.()
	}
}
