// Resume template — reads from ../data/resume.yaml
// Build: typst compile --root . --font-path resume/ resume/main.typ static/resume.pdf

#let data = yaml("../data/resume.yaml")

#set page(paper: "a4", margin: (x: 0.5in, y: 0.4in))
#set document(title: data.name + "'s Resume", author: data.name)
#set par(leading: 0.5em)
#set text(font: "Source Sans 3", size: 10pt)
#set underline(offset: 2.5pt)
#show heading: set text(weight: "semibold")
#show heading: it => { v(4pt); it; v(2pt) }

// --- Markdown bold **text** → Typst bold *text* ---
#let md(s) = {
  let converted = s.replace(regex("\*\*(.+?)\*\*"), m => "*" + m.captures.at(0) + "*")
  eval(converted, mode: "markup")
}

// --- Icon helper ---
#let icon(name, shift: 1.5pt) = {
  box(
    baseline: shift,
    height: 10pt,
    image("icons/" + name + ".svg", alt: name)
  )
  h(2pt)
}

// --- Links bar ---
#let linksBar(links) = {
  let icon = icon.with(shift: 2.5pt)
  links.map(l => {
    icon(l.icon)
    if "display" in l.keys() {
      link(l.url)[#{l.display}]
    } else {
      link(l.url)
    }
  }).join(h(5pt))
}

// --- Work experience entry ---
#let workExperience(body, company: "", role: "", start: "", end: "", location: "", stack: ()) = {
  grid(
    columns: (1fr, auto),
    row-gutter: (0.5em, ),
    align(left)[
      #set text(weight: "semibold")
      #company
    ],
    align(right)[
      #location
    ],
    align(left)[
      #set text(weight: "semibold")
      #role
    ],
    align(left)[
      #start - #end
    ],
    if stack.len() > 0 {
      grid.cell(colspan: 2, align: left)[
        #set text()
        Tech Stack: #stack.join(", ")
      ]
    }
  )
  body
}

// --- Project entry ---
#let project(body, name: "", stack: ()) = {
  text(weight: "semibold")[#name] + if stack.len() > 0 {
    [ | #stack.join(", ")]
  }
  body
}

// --- Education entry ---
#let educationQualification(body, school: "", course: "", start: "", end: "", location: "") = {
  grid(
    columns: (1fr, auto),
    row-gutter: (0.5em, ),
    align(left)[
      #set text(weight: "semibold")
      #school
    ],
    align(right)[
      #location
    ],
    align(left)[
      #set text(weight: "semibold")
      #course
    ],
    align(left)[
      #start - #end
    ]
  )
  body
}

// =============================================
// RENDER
// =============================================

// --- Header ---
#text(size: 28pt, weight: "semibold")[#data.name] \
#v(9pt, weak: true)
#text(size: 14pt)[#data.role]

// Contact links — first row
#linksBar((
  (icon: "phone", url: data.contact.phone.url, display: data.contact.phone.display),
  (icon: "email", url: data.contact.email.url),
  (icon: "website", url: data.contact.website.url, display: data.contact.website.display),
  (icon: "linkedin", url: data.contact.linkedin.url, display: data.contact.linkedin.display),
))
#linebreak()
// Contact links — second row
#linksBar((
  (icon: "git", url: data.contact.git.url, display: data.contact.git.display),
  (icon: "github", url: data.contact.github.url, display: data.contact.github.display),
))
#line(length: 100%)

// --- Experience ---
= Experience

#for exp in data.experience {
  workExperience(
    company: exp.company,
    role: exp.role,
    start: exp.start,
    end: exp.end,
    location: exp.location,
    stack: exp.at("stack", default: ()),
  )[
    #for bullet in exp.at("bullets", default: ()) {
      [- #md(bullet)]
    }
    #for l in exp.at("links", default: ()) {
      [- #underline(link(l.url)[#l.display])]
    }
  ]
}

// --- Skills ---
= Skills
#for skill in data.skills {
  [#text(weight: "semibold")[#skill.type]: #skill.items.join(", ") \ ]
}

// --- Projects ---
= Projects
#for p in data.projects {
  project(name: p.name, stack: p.at("stack", default: ()))[
    #let links = p.at("links", default: ())
    #if links.len() > 0 {
      [- #links.map(l => underline(link(l.url)[#l.display])).join(", ")]
    }
  ]
}

// --- Education ---
= Education
#for edu in data.education {
  educationQualification(
    school: edu.school,
    course: edu.course,
    location: edu.location,
    start: edu.start,
    end: edu.end,
  )[]
}