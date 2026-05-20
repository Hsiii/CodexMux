import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import ReactDOM from 'react-dom/client';

import { App } from './App.js';

import './index.css';

const queryClient = new QueryClient();
const rootElement = document.querySelector('#root');

if (rootElement === null) {
    throw new Error('Expected #root to exist before mounting the app.');
}

ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
        <QueryClientProvider client={queryClient}>
            <App />
        </QueryClientProvider>
    </React.StrictMode>
);
