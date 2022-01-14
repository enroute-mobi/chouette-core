import { useEffect } from "react"
import Alpine from 'alpinejs'

/*
This custom hook display a flash message based on data set previoulsy in the session storage.
The value in the session storage should be a JSON string with the following format :
	{
		resource: string,
		action: string,
		status: string
	}
*/

export default function useFlashMessage(key = 'previousAction') {
	useEffect(() => {
		const previousAction = sessionStorage.getItem(key)

		if (!previousAction) return

		try {
			const { resource, action, status } = JSON.parse(previousAction)

			Alpine.store('flash').add({
				type: 'success',
				text: I18n.t(`flash.actions.${action}.${status}`, {
					resource_name: I18n.t(`activerecord.models.${resource}.one`)
				})
			})

		} catch (_error) {
			// CHOUETTE-1522
			sessionStorage.clear()
		} finally {
			sessionStorage.removeItem(key)
		}
	}, [])
}
