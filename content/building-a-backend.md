---
title: "building a backend for my website... with zero knowledge"
date: 2022-05-26T18:04:45-03:00
summary: A webpage is a bit limited without some server-side handling. You know... like having cool URLs, and probably some other things as well that I don't care. But why don't use it as a learning experience? :)
draft: false
tags: ["backend", "rust"]
---
In my first blog post, [*Creating a basic on-prem personal blog*](http://grbenjamin.github.io/posts/creating-a-blog/), I noted what was the plan on building this website. I talked about how I was going to make everything from scratch, including the look of the page, its backend and a server to host it at home.

I thought that building the web server itself would take ages to do. But that was before trying to the the backend. Gosh, I really did think that was going to be super easy.

Originally, I was going to use [**Django**](https://www.djangoproject.com ) or [**Gin Gonic**](https://gin-gonic.com/) for that, but I googled a bit for other frameworks I could use, to get a broader look. The only framework I've used in the past was [**Spring**](https://spring.io/), so I thought I could use it. Not that I loved using it, but I liked how I could simply put an *annotation* above a method to specify the HTTP method used, like in, say *Flask* or *Express.js*. 
For example, let's say we have a Controller class that handles one route:

```java
@Controller
@RequestMapping("/")
public class MyController extends BaseController<MyType> {

    @RequestMapping(value = "/home", method = RequestMethod.GET)
    @ResponseBody
    public String getHomePage() {
        return "home";
    }

}
```

We can easily know this method `getHomePage()` is a *GET* request by looking at the body above it — `@RequestMapping`. You can specify the route that it is attached to in the **value** parameter. Its convenience catches my eye, as it makes it easier to read. 
It's not entirely clear what does *"home"* mean to someone that haven't touched Spring in their life, though. This is boilerplate that pretty much exist in 99% of a Java codebase. 
There are a **ton** of web frameworks in almost every single programming language, so there's a lot to choose from. Why Spring then?

## Rocket, and how it's basically just an excuse to learn Rust

Soon after I stumbled upon [**Rocket**](https://rocket.rs/), an HTTP framework written in **Rust**. I have heard of it before, but never actually gave it a look. Thought that writing a thing in Rust would only complicate things and not actually getting my stuff done *(I'm looking at you, [Actix](https://actix.rs/))*. 
Looking at its webpage, the first thing I saw was an example of use:

```rust 
#[macro_use] extern crate rocket;

#[get("/hello/<name>/<age>")]
fn hello(name: &str, age: u8) -> String {
    format!("Hello, {} year old named {}!", age, name)
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![hello])
}
```

... exactly what I was looking for! (almost) No boilerplates, no confusing class hierarchy, and I can route things with one macro above a function. You could even read it without knowing Rust and still understand what's going on.
You define a function that returns a string formatted with the name and age passed to the URL. How great is that? Then you simply mount it to your *main* function (in this case Rocket provides a wrapping with `rocket()`) and that's it!

I always have loved the Rust ecosystem and community. Everything is *Open Source*, everyone is willing to help you with any trouble you're having and everything is **very well documented**. But learning it is somewhat difficult. Every person I've known that is using Rust have dropped it at least 2 o 3 times before trying to learn it again. And that happened to me... at least 4 times. So I guess **Rocket** is an excuse to give Rust another try. :)

Starting wasn't difficult. Rocket's official tutorial covers up the basics to get you up and running building stuff. Then it's about adding more and more stuff in top of that stuff. Basically stuff of stuff. 
One of the first things I wanted to get working was the ability to enter a url like **/post/<id>** and see a post coming up in the page. At first glance, I thought I could write the post and then manually convert it to HTML to let Rocket render it. Not difficult, but that sure gets tedious after doing so 300 times. Just when I was about to make a simple tool to let me put Markdown into an HTML template, I found [**Tera**](https://github.com/Keats/tera), a templating engine for Rust, based on the **Jinja2/Django** templating.

Let's imagine you have a way to store Posts:

```rust
// Basic, for the sake of simplicity 
struct Post {
    title: &'static str,
    content: &'static str,
}
```

and you have the following HTML:

```html
<body>
    <!-- Other HTML stuff... -->

    <!-- Here goes your title -->
    <h1></h1>
    <!-- Here goes your content -->
    <p></p>
</body>
```

then all is left to do es combine the two of them to render it to the page:

```rust
// Call this function every time the user routes to /my_post
#[get("/my_post")]
fn get_post() -> Template {
    let post = Post {
        title: "my #1 post!!",
        content: "hey this is my first post :) heck yea"
    };

    Template::render("the_html_file_path", context! { post })
}
```
```html
<body>
    <h1>{{ post.title }}</h1>
    <!-- "safe" basically tells Tera 
    to render the markdown correctly -->
    <p>{{ post.content | safe }}</p>
</body>
```

and... voilà!

![Image of a landing page generated by the code above](/building-a-backend_01.png#center "A post generated by the code above")

That's it! You've created an HTML page from a *template* and data from a Rust struct. 
That's actually the most basic thing you can do in Tera. You could even do things like **for loops**, **condition checking** and even **define macros**.
For example, here's what I kind of use to render the links in the **Related** section:
```html
<ul>
{% for link in post.links %}
    <li><a href="{{ link.url }}">{{ link.title }}</a></li>
{% endfor %}
</ul>
```

This approach lets me focus more on the actual writing of the posts rather than manually converting and fixing stuff between each one. Combine that with a CommonMark to HTML converter like [**pulldown_cmark**](https://crates.io/crates/pulldown-cmark) and you're done, just write *.md* files and let the API handle everything for you.

## OK, but X does that and even more. Why not use it?
I really don't know. I just liked how Rocket handle things. Plus I think it's a great way of learn Rust. 
As I said in my previous post, I like learning stuff by trying and breaking everything, and this is exactly what I wanted in the first place. Rust is a tough language to learn, and if you don't have any meaningful reason on why to do it then it becomes impossible to do so. Rocket may be the thing that **launches** me (pun intended) onto learning more and more about the language. 

In the end, all of this is just programming practice and a learning experience. Getting fun is the solid reason why this blog exists, no matter what tool I use, as long as I have fun :)
