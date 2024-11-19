const ejs = require('ejs');
const fs = require('fs');
const path = require('path');

// Define the input (EJS templates) and output (public folder)
const templatesDir = path.join(__dirname, 'views');
const outputDir = path.join(__dirname, 'public');

// Ensure the public directory exists
fs.mkdirSync(outputDir, { recursive: true });

// List all template files
const templates = ['index.ejs']; // Add your template names

// Render each template to HTML
templates.forEach((template) => {
  const templatePath = path.join(templatesDir, template);
  const outputPath = path.join(outputDir, template.replace('.ejs', '.html'));

  // Render template and write the output to a file
  const html = ejs.render(fs.readFileSync(templatePath, 'utf-8'), { title: 'My Website' });
  fs.writeFileSync(outputPath, html);
  console.log(`Generated: ${outputPath}`);
});

