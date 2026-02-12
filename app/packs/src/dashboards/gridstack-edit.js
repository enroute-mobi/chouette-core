import { GridStack } from 'gridstack';
import * as Sentry from "@sentry/browser";

// Version for editing with drag & drop enabled
function initGridstack() {  
  const gridElement = document.querySelector('.grid-stack');
  
  if (!gridElement) {
    Sentry.captureMessage('Gridstack element not found', "warning"); 
    return;
  }
  // console.log('Found gridstack element:', gridElement);
  
  // Check that widgets are present
  const widgetItems = gridElement.querySelectorAll('.grid-stack-item');
  // console.log('Found widget items:', widgetItems.length);
  
  if (widgetItems.length === 0) {
    Sentry.captureMessage('No widget items found, aborting gridstack initialization', "warning"); 
    return;
  }
  
  // Initialize Gridstack v7.x with simple configuration
  let grid = GridStack.init({
    float: true,
    cellHeight: 70,        // Cell height
    margin: 8,
    resizable: {
      handles: 'e, se, s, sw, w'
    },
    draggable: {
      handle: '.widget-drag-handle',
      appendTo: 'body',    // To avoid alignment issues
      scroll: true,         // Allows scrolling during drag
      containment: document.body // Contain within body
    }
  }, gridElement);

  // console.log('Gridstack initialized successfully for editing');
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

  // Save widget positions on change
  grid.on('change', function(event, items) {
    console.log('Grid change event:', items);
    
    if (!items || !Array.isArray(items)) {
      // console.warn('Invalid items in change event:', items);
      Sentry.captureMessage(`Invalid items in change event: ${items}`, "warning");
      return;
    }
    
    items.forEach(function(item, index) {
      if (!item || !item.el) {
        // console.warn('Invalid item', index, item);
        Sentry.captureMessage(`Invalid item ${index}: ${item}`, "warning"); 
        return;
      }
      
      const widgetId = item.el.getAttribute('data-widget-id');
      if (!widgetId) {
        // console.warn('Item', index, 'has no widget-id:', item.el);
        Sentry.captureMessage(`Item ${index} has no widget-id: ${item.el}`, "warning"); 
        return;
      }
      
      const position = {
        x: item.x || 0,
        y: item.y || 0,
        width: item.w || 1,
        height: item.h || 1
      };
      
      // console.log('Saving position for widget', widgetId, position);
      saveWidgetPosition(gridElement, widgetId, position);
    });
  });

}

// Listen for page load events
document.addEventListener('DOMContentLoaded', initGridstack);

function saveWidgetPosition(gridElement, widgetId, position) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  
  const dashboardPath = gridElement.getAttribute('data-dashboard-path');
  
  fetch(dashboardPath, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({ widgets_attributes: { '0': { ...position, id: widgetId }}})
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
  })
}
