// Run from the repository root: node --test tests/rustypaste-upload.test.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

const html = readFileSync(
  new URL("../nix/features/services/rustypaste/landing.html", import.meta.url),
  "utf8",
);
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];

function page(fetch) {
  const elements = { drop: {}, file: {}, out: { textContent: "" } };
  const links = [];
  const requests = [];
  elements.out.append = (link) => links.push(link);
  const context = vm.createContext({
    document: {
      getElementById: (id) => elements[id],
      createElement: (tag) => {
        assert.equal(tag, "a");
        return {};
      },
    },
    // Clipboard is unavailable on the configured plain-HTTP LAN origin.
    navigator: {},
    FormData,
    fetch: async (url, options) => {
      requests.push({ url, options });
      return fetch();
    },
  });
  vm.runInContext(script, context);
  return {
    out: elements.out,
    links,
    requests,
    upload: async () => {
      context.file = new File(["hello"], "example.txt");
      await vm.runInContext("upload(file)", context);
    },
  };
}

for (const phase of ["request", "response body"]) {
  test(`reports a failed ${phase} and allows a subsequent upload`, async () => {
    let attempts = 0;
    const fixture = page(() => {
      if (attempts++ === 0) {
        const error = new TypeError("Connection lost");
        if (phase === "request") throw error;
        return {
          ok: true,
          text: async () => {
            throw error;
          },
        };
      }
      return new Response("http://pb/retry.txt\n");
    });
    await fixture.upload();
    assert.equal(fixture.out.textContent, "Upload failed: Connection lost");
    assert.equal(fixture.links.length, 0);
    await fixture.upload();
    assert.equal(fixture.links.length, 1);
    assert.equal(fixture.links[0].href, "http://pb/retry.txt");
  });
}

test("preserves HTTP error feedback without creating a download link", async () => {
  const fixture = page(() => new Response("File too large\n", { status: 413 }));
  await fixture.upload();
  assert.equal(fixture.out.textContent, "Upload failed: File too large");
  assert.equal(fixture.links.length, 0);
});

test("preserves multipart POST and the returned URL on success", async () => {
  const fixture = page(() => new Response("http://pb/example.txt\n"));
  await fixture.upload();
  assert.equal(fixture.requests.length, 1);
  const { url, options } = fixture.requests[0];
  assert.equal(url, "/");
  assert.equal(options.method, "POST");
  assert.deepEqual([...options.body.keys()], ["file"]);
  assert.equal(options.body.get("file").name, "example.txt");
  assert.equal(await options.body.get("file").text(), "hello");
  assert.equal(fixture.out.innerHTML, "");
  assert.equal(fixture.links.length, 1);
  assert.equal(fixture.links[0].href, "http://pb/example.txt");
  assert.equal(fixture.links[0].textContent, "http://pb/example.txt");
});
