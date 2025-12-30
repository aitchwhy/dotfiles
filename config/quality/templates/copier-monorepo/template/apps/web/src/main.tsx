import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

const rootElement = document.getElementById('root')

if (rootElement) {
	createRoot(rootElement).render(
		<StrictMode>
			<div className="flex min-h-screen items-center justify-center">
				<h1 className="text-2xl font-bold">Hello world</h1>
			</div>
		</StrictMode>,
	)
}
