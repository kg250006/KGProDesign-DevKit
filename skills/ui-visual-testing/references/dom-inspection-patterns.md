# DOM Inspection Patterns Reference

<objective>
Selector strategies, element validation, waiting patterns, and form state inspection techniques for Puppeteer-based DOM testing.
</objective>

---

## Selector Priority (Best to Worst)

Always prefer more stable selectors. Selectors at the top of this list are less likely to break when UI changes.

### 1. data-testid (Recommended)
```typescript
// Most stable - explicitly added for testing
await page.$('[data-testid="submit-button"]');
await page.$('[data-test="login-form"]');
await page.$('[data-cy="user-menu"]');  // Cypress convention
```
**Why**: Developers add these specifically for testing; won't change due to styling.

### 2. aria-label / aria-* Attributes
```typescript
// Good for accessibility and testing
await page.$('[aria-label="Close dialog"]');
await page.$('[aria-labelledby="section-heading"]');
await page.$('[role="dialog"]');
await page.$('[aria-expanded="true"]');
```
**Why**: Part of accessibility contract; changes break screen readers.

### 3. Semantic HTML Elements
```typescript
// Meaningful HTML structure
await page.$('button[type="submit"]');
await page.$('nav');
await page.$('main');
await page.$('header');
await page.$('form');
await page.$('input[type="email"]');
```
**Why**: Semantic meaning is stable; rarely changes without functional change.

### 4. ID Selectors
```typescript
// Unique but may change during refactoring
await page.$('#login-button');
await page.$('#user-profile');
```
**Why**: IDs should be unique but often change during refactoring.

### 5. Name Attributes (Forms)
```typescript
// Good for form fields
await page.$('input[name="email"]');
await page.$('select[name="country"]');
await page.$('textarea[name="comment"]');
```
**Why**: Form field names are functional; changing them breaks form submission.

### 6. Class Selectors (Less Stable)
```typescript
// May change with styling
await page.$('.submit-btn');
await page.$('.user-avatar');
```
**Why**: Classes often tied to CSS; can change during redesign.

### 7. Text Content (Last Resort)
```typescript
// XPath for text matching
await page.$x('//button[contains(text(), "Submit")]');
await page.$x('//h1[text()="Welcome"]');

// Using evaluate
await page.evaluate(() => {
  return Array.from(document.querySelectorAll('button'))
    .find(b => b.textContent?.includes('Submit'));
});
```
**Why**: Text can change (localization, copy updates); use only when necessary.

---

## Waiting Strategies

### waitForSelector
```typescript
// Wait for element to exist
await page.waitForSelector('.modal');

// Wait for element to be visible
await page.waitForSelector('.content', { visible: true });

// Wait for element to be hidden/removed
await page.waitForSelector('.loading', { hidden: true });

// With timeout
await page.waitForSelector('.data-loaded', { timeout: 10000 });
```

### waitForFunction
```typescript
// Wait for custom condition
await page.waitForFunction(
  () => document.querySelectorAll('.item').length >= 5
);

// Wait with arguments
await page.waitForFunction(
  (min: number) => document.querySelectorAll('.item').length >= min,
  {},
  5
);

// Wait for text content
await page.waitForFunction(
  (text: string) => document.body.innerText.includes(text),
  {},
  'Welcome back'
);

// Wait for element property
await page.waitForFunction(
  (selector: string, prop: string, value: any) => {
    const el = document.querySelector(selector);
    return el && (el as any)[prop] === value;
  },
  {},
  'input', 'value', 'test@example.com'
);
```

### waitForNavigation
```typescript
// Wait for page navigation
await Promise.all([
  page.waitForNavigation({ waitUntil: 'networkidle0' }),
  page.click('a.next-page'),
]);

// Different wait conditions
await page.waitForNavigation({ waitUntil: 'load' });
await page.waitForNavigation({ waitUntil: 'domcontentloaded' });
await page.waitForNavigation({ waitUntil: 'networkidle0' }); // No requests for 500ms
await page.waitForNavigation({ waitUntil: 'networkidle2' }); // ≤2 requests for 500ms
```

### waitForResponse / waitForRequest
```typescript
// Wait for specific API response
const response = await page.waitForResponse(
  res => res.url().includes('/api/users') && res.status() === 200
);
const data = await response.json();

// Wait for request to be made
await page.waitForRequest(req => req.url().includes('/api/submit'));

// With Promise.all
const [response] = await Promise.all([
  page.waitForResponse('/api/data'),
  page.click('#load-data'),
]);
```

### waitForNetworkIdle
```typescript
// Wait for network activity to settle
await page.waitForNetworkIdle({ idleTime: 500 });

// Navigate and wait
await page.goto(url, { waitUntil: 'networkidle0' });
```

---

## Element Validation Patterns

### Existence Check
```typescript
// Check if element exists
const element = await page.$('.my-element');
const exists = element !== null;

// Check multiple elements
const elements = await page.$$('.list-item');
const count = elements.length;
```

### Visibility Check
```typescript
// Check if visible (display, visibility, opacity)
const isVisible = await page.$eval('.element', (el) => {
  const style = window.getComputedStyle(el);
  return (
    style.display !== 'none' &&
    style.visibility !== 'hidden' &&
    parseFloat(style.opacity) > 0
  );
});

// Check if in viewport
const isInViewport = await page.$eval('.element', (el) => {
  const rect = el.getBoundingClientRect();
  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= window.innerHeight &&
    rect.right <= window.innerWidth
  );
});
```

### Text Content Check
```typescript
// Get text content
const text = await page.$eval('.heading', el => el.textContent);

// Get inner text (rendered text only)
const innerText = await page.$eval('.content', el => el.innerText);

// Check text contains
const hasText = await page.$eval('.message', (el, expected) => {
  return el.textContent?.includes(expected) ?? false;
}, 'success');
```

### Attribute Check
```typescript
// Get attribute value
const href = await page.$eval('a.link', el => el.getAttribute('href'));

// Check attribute exists
const hasAttr = await page.$eval('input', el => el.hasAttribute('disabled'));

// Get multiple attributes
const attrs = await page.$eval('.button', el => ({
  id: el.id,
  disabled: el.hasAttribute('disabled'),
  ariaLabel: el.getAttribute('aria-label'),
}));

// Get all attributes
const allAttrs = await page.$eval('.element', el => {
  return Object.fromEntries(
    Array.from(el.attributes).map(a => [a.name, a.value])
  );
});
```

### Class Check
```typescript
// Check if has class
const hasClass = await page.$eval('.element', (el, className) => {
  return el.classList.contains(className);
}, 'active');

// Get all classes
const classes = await page.$eval('.element', el => Array.from(el.classList));
```

### Style Check
```typescript
// Get computed style
const bgColor = await page.$eval('.element', el => {
  return window.getComputedStyle(el).backgroundColor;
});

// Check multiple styles
const styles = await page.$eval('.button', el => {
  const computed = window.getComputedStyle(el);
  return {
    display: computed.display,
    opacity: computed.opacity,
    cursor: computed.cursor,
    backgroundColor: computed.backgroundColor,
  };
});
```

---

## Form State Validation

### Input Fields
```typescript
// Get input value
const value = await page.$eval('input[name="email"]', (el: HTMLInputElement) => el.value);

// Check if disabled
const isDisabled = await page.$eval('input', (el: HTMLInputElement) => el.disabled);

// Check if required
const isRequired = await page.$eval('input', (el: HTMLInputElement) => el.required);

// Check validity
const isValid = await page.$eval('input', (el: HTMLInputElement) => el.validity.valid);

// Get validation message
const validationMsg = await page.$eval('input', (el: HTMLInputElement) => el.validationMessage);

// Check placeholder
const placeholder = await page.$eval('input', (el: HTMLInputElement) => el.placeholder);

// Get input type
const type = await page.$eval('input', (el: HTMLInputElement) => el.type);
```

### Checkboxes and Radio Buttons
```typescript
// Check if checked
const isChecked = await page.$eval('input[type="checkbox"]', (el: HTMLInputElement) => el.checked);

// Get all checked values
const checkedValues = await page.$$eval('input[type="checkbox"]:checked', (els) =>
  els.map((el: HTMLInputElement) => el.value)
);

// Get selected radio value
const radioValue = await page.$eval('input[name="option"]:checked', (el: HTMLInputElement) => el.value);
```

### Select Dropdowns
```typescript
// Get selected value
const selectedValue = await page.$eval('select', (el: HTMLSelectElement) => el.value);

// Get selected text
const selectedText = await page.$eval('select', (el: HTMLSelectElement) =>
  el.options[el.selectedIndex]?.text
);

// Get all options
const options = await page.$eval('select', (el: HTMLSelectElement) =>
  Array.from(el.options).map(o => ({ value: o.value, text: o.text }))
);

// Check if multi-select
const isMultiple = await page.$eval('select', (el: HTMLSelectElement) => el.multiple);

// Get all selected (multi-select)
const selected = await page.$eval('select[multiple]', (el: HTMLSelectElement) =>
  Array.from(el.selectedOptions).map(o => o.value)
);
```

### Form State Snapshot
```typescript
// Get complete form state
const formState = await page.$eval('form', (form: HTMLFormElement) => {
  const data: Record<string, any> = {};
  const formData = new FormData(form);

  for (const [key, value] of formData.entries()) {
    if (data[key]) {
      if (!Array.isArray(data[key])) {
        data[key] = [data[key]];
      }
      data[key].push(value);
    } else {
      data[key] = value;
    }
  }

  return data;
});
```

---

## Common Validation Patterns

### Table Validation
```typescript
// Get table data
const tableData = await page.$$eval('table tbody tr', rows =>
  rows.map(row => {
    const cells = row.querySelectorAll('td');
    return Array.from(cells).map(cell => cell.textContent?.trim());
  })
);

// Get table headers
const headers = await page.$$eval('table thead th', ths =>
  ths.map(th => th.textContent?.trim())
);

// Get specific cell
const cell = await page.$eval('table tbody tr:nth-child(2) td:nth-child(3)', el => el.textContent);
```

### List Validation
```typescript
// Get list items
const items = await page.$$eval('ul.list li', lis =>
  lis.map(li => li.textContent?.trim())
);

// Count items
const count = await page.$$eval('.list-item', els => els.length);

// Find item by text
const found = await page.$eval('.list', (list, searchText) => {
  const item = Array.from(list.querySelectorAll('li'))
    .find(li => li.textContent?.includes(searchText));
  return item?.textContent;
}, 'Search Term');
```

### Modal/Dialog Validation
```typescript
// Check if modal is visible
const modalVisible = await page.$eval('.modal', el => {
  const style = window.getComputedStyle(el);
  return style.display !== 'none' && style.visibility !== 'hidden';
}).catch(() => false);

// Get modal content
const modalContent = await page.$eval('.modal .modal-body', el => el.textContent);

// Check modal title
const modalTitle = await page.$eval('.modal .modal-title', el => el.textContent);
```

### Error Message Validation
```typescript
// Check for error message
const hasError = await page.$('.error-message, .validation-error, [role="alert"]') !== null;

// Get error text
const errorText = await page.$eval('.error-message', el => el.textContent).catch(() => null);

// Get all field errors
const fieldErrors = await page.$$eval('.field-error', errors =>
  errors.map(e => ({
    field: e.getAttribute('data-field'),
    message: e.textContent,
  }))
);
```

---

## Performance Tips

### Batch Evaluations
```typescript
// Bad: Multiple round trips
const name = await page.$eval('#name', el => el.textContent);
const email = await page.$eval('#email', el => el.textContent);
const phone = await page.$eval('#phone', el => el.textContent);

// Good: Single evaluation
const { name, email, phone } = await page.evaluate(() => ({
  name: document.querySelector('#name')?.textContent,
  email: document.querySelector('#email')?.textContent,
  phone: document.querySelector('#phone')?.textContent,
}));
```

### Reuse ElementHandles
```typescript
// Get handle once, use multiple times
const button = await page.$('.submit-button');
if (button) {
  const isDisabled = await button.evaluate((el: HTMLButtonElement) => el.disabled);
  const text = await button.evaluate(el => el.textContent);
  await button.click();
}
```

### Avoid Unnecessary Waits
```typescript
// Bad: Always wait 2 seconds
await page.waitForTimeout(2000);
await page.click('.button');

// Good: Wait for specific condition
await page.waitForSelector('.button', { visible: true });
await page.click('.button');
```
