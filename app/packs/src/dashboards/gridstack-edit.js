import { GridStack } from 'gridstack';

// Version for editing with drag & drop enabled
function initGridstack() {
  console.log('DOM loaded, looking for gridstack element...');
  
  const gridElement = document.querySelector('.grid-stack');
  
  if (!gridElement) {
    console.error('Gridstack element not found');
    return;
  }
  
  console.log('Found gridstack element:', gridElement);
  
  // Check that widgets are present
  const widgetItems = gridElement.querySelectorAll('.grid-stack-item');
  console.log('Found widget items:', widgetItems.length);
  
  if (widgetItems.length === 0) {
    console.warn('No widget items found, aborting gridstack initialization');
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

  console.log('Gridstack initialized successfully for editing');
  console.log('Gridstack engine nodes:', grid.engine.nodes.length);

  // Check positions after initialization
  setTimeout(() => {
    const nodes = grid.engine.nodes;
    console.log('Gridstack nodes after delay:', nodes.length);
    nodes.forEach((node, index) => {
      console.log(`Node ${index}:`, {
        id: node.el?.getAttribute('data-widget-id'),
        x: node.x,
        y: node.y,
        w: node.w,
        h: node.h,
        hasEl: !!node.el
      });
    });
  }, 200);

  // Save widget positions on change
  grid.on('change', function(event, items) {
    console.log('Grid change event:', items);
    
    if (!items || !Array.isArray(items)) {
      console.warn('Invalid items in change event:', items);
      return;
    }
    
    items.forEach(function(item, index) {
      if (!item || !item.el) {
        console.warn(`Invalid item ${index}:`, item);
        return;
      }
      
      const widgetId = item.el.getAttribute('data-widget-id');
      if (!widgetId) {
        console.warn(`Item ${index} has no widget-id:`, item.el);
        return;
      }
      
      const position = {
        x: item.x || 0,
        y: item.y || 0,
        width: item.w || 1,
        height: item.h || 1
      };
      
      console.log('Saving position for widget', widgetId, position);
      saveWidgetPosition(widgetId, position);
    });
  });

}

// Listen for page load events
document.addEventListener('DOMContentLoaded', initGridstack);

// For Turbolinks if used
document.addEventListener('turbolinks:load', initGridstack);

// For Turbo if used (Rails 7)
document.addEventListener('turbo:load', initGridstack);

function saveWidgetPosition(widgetId, position) {
  const dashboardElement = document.querySelector('[data-dashboard-id]');
  if (!dashboardElement) {
    console.error('Dashboard element not found');
    return;
  }
  
  const workbenchId = dashboardElement.getAttribute('data-workbench-id');
  const dashboardId = dashboardElement.getAttribute('data-dashboard-id');
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  
  if (!workbenchId || !dashboardId || !csrfToken) {
    console.error('Missing required data for saving position');
    return;
  }
  
  fetch(`/workbenches/${workbenchId}/dashboards/${dashboardId}/widgets/${widgetId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({ widget: { x: position.x, y: position.y, width: position.width, height: position.height } })
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(data => {
    console.log('Widget position saved successfully:', data);
  })
  .catch(error => {
    console.error('Error saving widget position:', error);
  });
}
