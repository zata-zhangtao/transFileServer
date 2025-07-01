// Import React library - the core React functionality
import React from 'react';

// Import ReactDOM - specifically the client-side rendering functions
// ReactDOM is responsible for rendering React components into the browser's DOM
import ReactDOM from 'react-dom/client';

// Import global CSS styles that apply to the entire application
import './index.css';

// Import our main App component - this is the root component of our application
import App from './App';

// Import performance monitoring utility (optional)
import reportWebVitals from './reportWebVitals';

// Create a React root - this is the new way in React 18+
// We're finding the HTML element with id="root" and creating a React root from it
// This element is defined in public/index.html
const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
  // 'as HTMLElement' is TypeScript syntax to tell the compiler we know this will be an HTMLElement
);

// Render our application into the root element
root.render(
  // React.StrictMode is a wrapper component that helps identify potential problems
  // It activates additional checks and warnings for its descendants
  // Only runs in development mode, doesn't affect production builds
  <React.StrictMode>
    {/* This is where our main App component gets rendered */}
    <App />
  </React.StrictMode>
);

// Optional: Performance monitoring
// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals

// This function can measure and report various performance metrics
// like Cumulative Layout Shift (CLS), First Input Delay (FID), etc.
reportWebVitals();

// Key concepts explained:
// 1. This file is the entry point of the React application
// 2. ReactDOM.createRoot() creates a root that can render React components
// 3. root.render() actually displays the components in the browser
// 4. Everything starts here and flows down through the component tree
// 5. The App component becomes the parent of all other components
