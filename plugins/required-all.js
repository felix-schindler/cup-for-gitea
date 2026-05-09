export default function requiredAllPlugin() {
  return {
    id: "local",
    decorators: {
      oas3: {
        "required-all": () => ({
          Schema: {
            leave(schema) {
              if (!schema || schema.type !== "object" || !schema.properties) {
                return;
              }

              const properties = Object.keys(schema.properties);
              if (properties.length === 0) {
                return;
              }

              const required = new Set(schema.required || []);
              for (const name of properties) {
                required.add(name);
              }

              schema.required = Array.from(required);
            },
          },
        }),
      },
    },
  };
}
