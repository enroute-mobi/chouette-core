import { GridStack } from 'gridstack';
import * as Sentry from "@sentry/browser";

// Version for static visualization (read-only)
function initGridstack() {
  // console.log('DOM loaded, looking for gridstack element...');
  
  const gridElement = document.querySelector('.grid-stack');
  
  if (!gridElement) {
    Sentry.captureMessage('Gridstack element not found', "error"); 
    return;
  }
    
  // Check that widgets are present
  const widgetItems = gridElement.querySelectorAll('.grid-stack-item');
  // console.log('Found widget items:', widgetItems.length);
  
  if (widgetItems.length === 0) {
    // console.warn('No widget items found, aborting gridstack initialization');
    Sentry.captureMessage('No widget items found, aborting gridstack initialization', "warning"); 
    return;
  }
  
  // Initialize Gridstack v7.x in static mode (no drag & drop)
  // SAME PARAMETERS as editing for consistency
  let grid = GridStack.init({
    float: true,
    staticGrid: true,  // Static mode - no drag & drop
    resizable: false,  // No resize
    cellHeight: 70     // Same cell height as editing
  }, gridElement);

  // console.log('Gridstack initialized successfully for viewing (read-only)');
  // console.log('Gridstack engine nodes:', grid.engine.nodes.length);

  // Check positions after initialization
  // setTimeout(() => {
  //   const nodes = grid.engine.nodes;
  //   console.log('Gridstack nodes after delay:', nodes.length);
  //   nodes.forEach((node, index) => {
  //     console.log(`Node ${index}:`, {
  //       id: node.el?.getAttribute('data-widget-id'),
  //       x: node.x,
  //       y: node.y,
  //       w: node.w,
  //       h: node.h,
  //       hasEl: !!node.el
  //     });
  //   });
  // }, 200);
}

// Listen for page load events
document.addEventListener('DOMContentLoaded', initGridstack);
