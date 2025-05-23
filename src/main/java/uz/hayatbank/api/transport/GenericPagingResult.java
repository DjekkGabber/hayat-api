package uz.hayatbank.api.transport;

import lombok.Data;
import lombok.EqualsAndHashCode;

@EqualsAndHashCode(callSuper = true)
@Data
public class GenericPagingResult extends GenericResult {
    private Integer total;
    private Integer pages;
    private Integer current;
}
