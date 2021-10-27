module.exports = {
	globals: {
		fetch: () => {
			return Promise.resolve({
				json: () => Promise.resolve({})
			})
		}
	},
	roots: [
		"<rootDir>/spec/javascript"
	],
	testRegex: "(/test/.*|(\\_|/)spec)\\.js$",
	transform: {
		"^.+\\.coffee$": "<rootDir>/spec/javascript/preprocessor.js",
		"^.+\\.jsx?$": "babel-jest"
	},
	transformIgnorePatterns: [
		"/node_modules/(?!(ol)/).*/"
	],
	testEnvironment: "jest-environment-jsdom-global",
	setupFiles: [
		"<rootDir>/spec/javascript/spec_helper.js",
		"jest-plugin-context/setup",
		"jest-plugin-set/setup"
	]
}
